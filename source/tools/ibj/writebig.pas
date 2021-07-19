{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
// WRITEBIG - support for writing object files
// WRITEBIG.c Copyright 2003 NB Information Limited
// Converted to Free Pascal by JD McMullin, PhD  9th Dec 2020

// Support routines to allow the object file to be written in
// a "scatter gun" way, without thrashing the disk too much.
// The caller can append small numbers of bytes to any section
// of the file, and we will take care of buffering and seeking
// to the right place(s).

unit writebig;
interface

  procedure setDebug();
  procedure clearDebug();
  procedure setfile( fout : longint; offset : longint );
  procedure setsize( section : integer; s : longint );
  function getRawBase(): longint;
  function getRawDataSize( section : integer ): longint;
  function getRawDataBase( section : integer ): longint;
  function getRawDataOffset( section : integer ): longint;
  procedure writebyte( section : integer; b : byte );
  procedure writew16( section, w : integer );
  procedure writew32( section, w : integer );
  procedure flushout();

implementation
uses
  sysutils,
  sectdef;

const
  NSECTIONS = 20;
  NBUFFERS  = 4;  // NBUFFERS must be less than NSECTIONS
  BUFSIZE   = 512;

type
  secbuff =
  record
	which : integer;
	count : 0..BUFSIZE;
	buffer : array [1..BUFSIZE] of byte;
  end;

  tRawData =
  record
    base : longint;
    size : longint;
    offset : longint;
  end;

var
  debug : boolean = false;
  // our buffer data structure is designed to scale to allow rather more
  // sections that we might sensibly provide buffers for...  We use the
  // buffers as a cache of section information
  sb : array [1..NBUFFERS] of secbuff;
  nextFreeBuffer : integer;

  // Output file information
  rawbase : longint;
  handle  : longint; // file handle for random access file

  // section specific data
  rawdata : array [1..NSECTIONS] of tRawData;

  procedure showstatus( s : integer );
  var
    i : integer;
  begin
    writeln('**** DEBUG **** writebig: start status');
    writeln('  attempting to write to section ',s,' name=',sectIdToName(s));
    writeln('  section[',s,'].base=',rawdata[s].base);
    writeln('  section[',s,'].offset=',rawdata[s].offset);
    writeln('  section[',s,'].size=',rawdata[s].size);

    writeln('  BUFFER data');
    for i := 1 to NBUFFERS do
    begin
      writeln('    Details for buffer ',i);
      writeln('      used by section ',sb[i].which,' name=',sectIdToName(sb[i].which) );
      writeln('      buffer.count =',sb[i].count,' limit=',BUFSIZE);
    end;
    writeln('**** DEBUG **** writebig: end status');
  end;

  procedure setDebug();
  begin
    debug := true;
  end;

  procedure clearDebug();
  begin
    debug := false;
  end;

  // routine to describe the output file.  Must be called to
  // initialise the output process.
  procedure setfile( fout : longint; offset : longint);
  var
    i : integer;
  begin
    handle  := fout;
    rawbase := offset;
    nextFreeBuffer := 1;

    // initialise the section rawdata core data
    for i := 1 to NSECTIONS do
    begin
      rawdata[i].base := 0;
      rawdata[i].size := 0;
      rawdata[i].offset := 0;
    end;

    // take this opportunity to zap the buffer structures
    for i := 1 to NBUFFERS do
    begin
      sb[i].which := -1;
    end;
  end;

  // routine to establish the size of a section.
  // Must be called for each active section
  // BEFORE any output is attempted
  procedure setsize( section : integer; s : longint );
  var
    i : integer;
    offset : longint;
  begin
    rawdata[section].size := s;

    // now recompute the offsets
    offset := rawbase;
    for i := 1 to NSECTIONS do
    begin
      rawdata[i].base := offset;
      rawdata[i].offset := rawdata[i].base;
      offset := offset + rawdata[i].size;
    end;
  end;

  function getRawBase(): longint;
  begin
    getRawBase := rawbase;
  end;

  function getRawDataSize( section : integer ): longint;
  begin
    getRawDataSize := rawdata[section].size;
  end;

  function getRawDataBase( section : integer ): longint;
  begin
    getRawDataBase := rawdata[section].base;
  end;

  function getRawDataOffset( section : integer ): longint;
  begin
    getRawDataOffset := rawdata[section].offset;
  end;

  procedure flushBuffer( bufferId : integer );
  var
    sectionId : integer;
    count : longint;
  begin
    // find out which section this buffer is for
    sectionId := sb[bufferId].which;

    // find out how many byte to write out
    count := sb[bufferId].count;

    // move to appropriate rawdata section
    FileSeek( handle, rawdata[sectionId].offset, fsFromBeginning);
    // write the data
    FileWrite( handle, sb[bufferId].buffer, count );
    // flush data to file
    FileFlush( handle );
    // update the appropriate rawdata pointer
    rawdata[sectionId].offset := rawdata[sectionId].offset + count;

    // empty the buffer
    sb[bufferId].count := 0;
    // mark the buffer as free to be used
    sb[bufferId].which := -1;
  end;

  // write the byte to the appropriate buffer
  procedure addByte( bufferIndex : integer; b : byte );
  var
    count : integer;
  begin
    count := sb[bufferIndex].count + 1;
    sb[bufferIndex].buffer[count] := b;
    sb[bufferIndex].count := count;
  end;

  function incrementBufferIndex( oldIndex : integer ): integer;
  var
    newIndex : integer;
  begin
    if (oldIndex = NBUFFERS) then newIndex := 1 else newIndex := oldIndex + 1; // wrap if needed
    incrementBufferIndex := newIndex;
  end;

  // write the byte B to the appropriate section
  procedure writebyte( section : integer; b : byte );
  var
    i : integer;
    scribbled : boolean;
  begin
    if debug then showstatus( section );

    scribbled := false; // not been written to the buffers yet
    for i := 1 to NBUFFERS do
    begin
      // if active buffer for this section
      if (sb[i].which = section) then
      begin
        // update count and write to buffer
        addByte( i, b );
        // if the buffer is full
        if (sb[i].count = BUFSIZE)	then // full
        begin
          flushBuffer( i );
        end;
        scribbled := true
      end;
    end;

    // not found...look for one to re-use
    if not scribbled then
    begin
      // we need to find a free buffer
      // BEWARE all buffers might be used
      i := nextFreeBuffer;
      repeat
        if (sb[i].which <> -1) then
        begin
          if (i = NBUFFERS) then i := 1 else i := i + 1;
        end;
      until (i = nextFreeBuffer) or (sb[i].which = -1);

      // entry i is the one we'll use.  It may however be occupied
      // so if buffer is active AND not empty
      if ((sb[i].which <> -1) and (sb[i].count <> 0)) then
      begin
        flushBuffer( i );
      end;
      // now claim this buffer for the section
      sb[i].which := section; // now it is ours
      addByte( i, b );

      // finally, arrange that next time we start with the next entry
      nextFreeBuffer := nextFreeBuffer + 1;
      if (nextFreeBuffer = NBUFFERS) then nextFreeBuffer := 1;
    end;
  end;

  // wider version of writebyte
  procedure writew16( section, w : integer );
  begin
    if debug then showstatus( section );

    writebyte(section, (w shr 0) and $ff );
    writebyte(section, (w shr 8) and $ff );
  end;

  // wider still
  procedure writew32( section, w : integer );
  begin
    if debug then showstatus( section );

    writebyte(section, (w shr  0) and $ff ); // least significat byte?
	writebyte(section, (w shr  8) and $ff );
	writebyte(section, (w shr 16) and $ff );
	writebyte(section, (w shr 24) and $ff );
  end;

  // and write a whole lump (generally a struct, but we don't care)
  procedure writestring( section : integer; buffer : string);
  var
    i : integer;
  begin
    for i := 1 to length(buffer) do
    begin
      writebyte(section, ord(buffer[i]));
    end;
  end;

  procedure flushout();
  var
	i : integer;
  begin
    // for each buffer
    for i := 1 to NBUFFERS do
    begin
      // if buffer is active for a section
      if (sb[i].which >= 0) then
      begin
        flushBuffer( i );
      end;
    end;
  end;
 
 end.