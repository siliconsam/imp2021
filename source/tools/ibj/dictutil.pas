{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit dictUtil;
interface

  procedure initialiseDictionary();
  procedure writeDictionary( var fdebug : text; fout : longint; location : longint );
  function getDictionarySize(): longint;
  function formDictString( dict : integer ): string;
  function appendStringToDictionary( var fdebug : text; name : string ): integer;
  procedure loadDictionary( var fout : text; fin : longint; offset : longint; size : integer );
  procedure dumpDictionary( var fout : text );

implementation
uses
  dos,
  sysutils;

const
  MaxDictionary  = 50000;

type
  tDictionary =
  packed record
    debugFlag : boolean;
    dictionary : array [0..MaxDictionary] of byte;
  end;

var
  Symbols : tDictionary;

  // internal routines
  procedure setDictionarySize( ds : longint );
  begin
    Symbols.dictionary[0] := ds and $ff; ds := ds shr 8;
    Symbols.dictionary[1] := ds and $ff; ds := ds shr 8;
    Symbols.dictionary[2] := ds and $ff; ds := ds shr 8;
    Symbols.dictionary[3] := ds and $ff;
  end;

  // global routines
  procedure initialiseDictionary();
  begin
    Symbols.debugFlag := false;
    setDictionarySize( 4 ); // 2 bytes for dictionary size word + 2 bytes for zero'th name
  end;

  procedure writeDictionary( var fdebug : text; fout : longint; location : longint );
  var
    status : integer;
    size : longint;
  begin
    size := getDictionarySize();
    status := FileSeek( fout, location, fsFromBeginning);
    status := FileWrite( fout, Symbols.dictionary, size );
    FileFlush( fout );

    if Symbols.debugFlag then
    begin
      writeln( fdebug, '**** DEBUG **** writeDictionary: Write of ',IntToHex(status,4),' bytes v ',IntToHex(size,4),' bytes requested' );
    end;

  end;

  function getDictionarySize(): longint;
  var
    ds : longint;
  begin
    ds := 0;
    ds := ds + (Symbols.dictionary[3] and $ff); ds := ds shl 8;
    ds := ds + (Symbols.dictionary[2] and $ff); ds := ds shl 8; 
    ds := ds + (Symbols.dictionary[1] and $ff); ds := ds shl 8;
    ds := ds + (Symbols.dictionary[0] and $ff);
    getDictionarySize := ds and $ffffffff;
  end;

  function formDictString( dict : integer ): string;
  var
    i : integer;
    result : string;
  begin
    result := '';
    i := dict;
    // make sure we have a legal start point
    // also, overlapping names is not permitted
    if (3 < dict) and (dict < getDictionarySize()) and (Symbols.dictionary[dict-1] = 0) then
    begin
      while (Symbols.dictionary[i] <> 0) do
      begin
        result := result + chr(Symbols.dictionary[i]);
        i := i + 1;
      end;
    end;

    formDictString := result;
  end;

  function appendStringToDictionary( var fdebug : text; name : string ): integer;
  var
    i     : integer;
    ds    : longint;
    limit : longint;
    result : integer;
  begin
    if Symbols.debugFlag then
    begin
      writeln( fdebug, 'appendStringToDictionary:     dictionary size: ',IntToHex( getDictionarySize(), 8) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[0]: ',IntToHex( Symbols.dictionary[0], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[1]: ',IntToHex( Symbols.dictionary[1], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[2]: ',IntToHex( Symbols.dictionary[2], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[3]: ',IntToHex( Symbols.dictionary[3], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:         adding name: ',name );
    end;
    // Set the top limit of string-table size;
    limit := MaxDictionary;
    // evaluate the dictionary size
    ds := getDictionarySize();

    // jam Name into dictionary
    if ((length(name) + ds) < limit) then
    begin
      // note the name's dictionary index
     result := ds;

      // add the name text to the dictionary text
      for i := 1 to length(name) do
      begin
        Symbols.dictionary[ds + i - 1] := ord(name[i]);
      end;
      // don't forget the string terminator
      Symbols.dictionary[ds + length(name)] := 0;
      // remember the dictionary size == next free slot in dictionary
      ds := ds + length(name) + 1;
    end
    else
    begin
      // drat, not enough space
      // set this name's proposed "dict" pointer to the empty string location
      result := 2;

      // now report overflow for implementation
      writeln( fdebug, '**** FATAL **** String table overflow for this 32-bit COFF implementation');
      writeln( fdebug, '**** INFO  **** Increase current MaxDictionary value ',IntToHex(limit,8),' up to a maximum of $0000ffff (== 65535)' );
      writeln(         '**** FATAL **** String table overflow for this 32-bit COFF implementation');
      writeln( fdebug, '**** INFO  **** Increase current MaxDictionary value ',IntToHex(limit,8),' up to a maximum of $0000ffff (== 65535)' );
    end;
    // Don't forget to remember the dictionary size (inside the dictionary)
    setDictionarySize( ds );

    if Symbols.debugFlag then
    begin
      writeln( fdebug, 'appendStringToDictionary: new dictionary size: ',IntToHex( getDictionarySize(), 8) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[0]: ',IntToHex( Symbols.dictionary[0], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[1]: ',IntToHex( Symbols.dictionary[1], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[2]: ',IntToHex( Symbols.dictionary[2], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:       dictionary[3]: ',IntToHex( Symbols.dictionary[3], 2 ) );
      writeln( fdebug, 'appendStringToDictionary:              result: ',IntToHex( result, 4 ) );
    end;

    appendStringToDictionary := result;
  end;

  procedure loadDictionary( var fout : text; fin : longint; offset : longint; size : integer );
  var
    status : longint;
  begin
    status := FileSeek( fin, offset, fsFromBeginning);
    status := FileRead( fin, Symbols.dictionary, size );
    if Symbols.debugFlag then
    begin
      writeln( fout, '**** DEBUG **** loadDictionary: Loaded ',IntToHex(status,4),' bytes out of ',IntToHex(size,4),' bytes requested' );
    end;

    if (size <> getDictionarySize()) then
    begin
      writeln( fout, '**** ERROR **** loadDictionary: Mismatch between loaded size=',IntToHex(size,4),' and DictionarSize=',IntToHex(getDictionarySize(),4) );
    end;
  end;

  procedure dumpDictionary( var fout : text );
  var
    startLoc : integer;
    loc : integer;
    seq : integer;
    name : string;
  begin
    // move to first non-empty string
    startLoc := 4;
    loc := 4;
    seq := 1;
    name := '';
    if Symbols.debugFlag then
    begin
      writeln( fout, '**** DEBUG **** dumpDictionary: DictionarySize =',IntToHex(getDictionarySize(),4) );
    end;

    while (loc < getDictionarySize()) do
    begin
      if (Symbols.dictionary[loc] = 0) then
      begin
        writeln( fout, 'String[',IntToHex(seq,4),',@',IntToHex(startLoc,4),']= "',name, '"' );
        seq := seq + 1;
        name := '';
        startLoc := loc + 1;
      end
      else
      begin
        name := name + chr(Symbols.dictionary[loc]);
      end;
      loc := loc + 1;
    end;
  end;
  
end.
