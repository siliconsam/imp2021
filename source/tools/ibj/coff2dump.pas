{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program coff2dump;
uses
  sysutils,
  strutils,
  coffdefs,
  dateutils;

const
  Version = 'COFF 1.0';

type
  tCoffFile =
  record
    name      : string;
    handle    : longint;
    header    : cofffilehdr;
    mainprog  : boolean; // main prog or collection of external routines
    // derived values
    strTabPtr : longint; // pointer to the string table
    strTabSz  : word; // size of the string table
    // the output file
    fout      : text;
  end;

  function nibbleToHex( n : byte ): char;
  begin
    if n < 10 then
      nibbleToHex := chr( ord( '0' ) + n )
    else
      nibbleToHex := chr( ord( 'A' ) + n - 10 );
  end;

  function charToHex( ch : char ):string;
  var
    i : byte;
  begin
    i := ord( ch );
    charToHex := nibbleToHex( (i shr 4) and $f ) + nibbleToHex( i and $f );
  end;

  function getStringEntry(  var theFile : tCoffFile; stringindex : longint ): string;
  const
    maxstringsize = 256;
  var
    status : longint;
    stringvalue : array [0..maxstringsize-1] of byte;
    stringsize : integer;
    name : string;
    i : integer;
  begin
    // Assume maximum size
    stringsize := maxstringsize;
    // but defend against overflow when reading from the string table
    if (stringindex + stringsize > theFile.strTabSz ) then
    begin
      stringsize := theFile.strTabSz - stringindex;
    end;

    status := FileSeek( theFile.handle, theFile.strtabptr + stringindex, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('getStringEntry: Unable to seek symbolentry# ',stringindex );
    end;
    status := FileRead( theFile.handle, stringvalue, stringsize );
    if (status = -1) then
    begin
      writeln('getStringEntry: Unable to read symbolentry#',stringindex );
    end;
    if (status <> stringsize) then
    begin
      writeln('getStringEntry: Could not read complete data for symbolentry#',stringindex,', only ',status,' bytes read');
    end;

    name := '';
    i := 0;
    while (stringvalue[i] <> 0) and (i <= stringsize) do
    begin
      // Use 7 bit ASCII code values only
      if (31 < stringvalue[i]) and (stringvalue[i] < 127) then
      begin
        name := name + chr(stringvalue[i]);
      end;
      i := i + 1;
    end;

    getStringEntry := name;
  end;

  function getSymbolName( var theFile : tCoffFile; symbolId : longint ): string;
  var
    status : longint;
    symbolentry : coffsyment;
    name : string;
    i : integer;
  begin
    status := FileSeek( theFile.handle, theFile.header.f_symptr + symbolId*SZCOFFSYMENT, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('getSymbolName: Unable to seek symbolentry# ',symbolId );
    end;
    status := FileRead( theFile.handle, symbolentry, SZCOFFSYMENT );
    if (status = -1) then
    begin
      writeln('getSymbolName: Unable to read symbolentry#',symbolId );
    end;
    if (status <> SZCOFFSYMENT) then
    begin
      writeln('getSymbolName: Could not read complete data for symbolentry#',symbolId,', only ',status,' bytes read');
    end;

    name := '';
    if (symbolentry.n.n_n.n_zeroes = 0) then
    begin
      // need to access string table using symbolentry.n.n_n.n_offset
      name := getStringEntry( theFile, symbolentry.n.n_n.n_offset );
    end
    else
    begin
      for i := 0 to SYMNMLEN - 1 do
      begin
        if symbolentry.n.n_name[i] <> chr(0) then
        begin
          name := name + symbolentry.n.n_name[i];
        end;
      end;
    end;

    getSymbolName := name;
  end;

  procedure traverseSymbolTable( var theFile : tCOFFFile );
  var
    status : longint;
    symbolentry : coffsyment;
    auxentry : coffauxscn;
    fileentry : coffaux4;
    entryId : longint;
    auxentryId : longint;
    symbolname : string;
    filename : string;
    i,j : integer;
  begin
    entryId := 0;

    writeln( theFile.fout );
    writeln( theFile.fout, 'COFF SYMBOL TABLE' );

    while (entryId < theFile.header.f_nsyms) do
    begin
      status := FileSeek( theFile.handle, theFile.header.f_symptr + entryId*SZCOFFSYMENT, fsFromBeginning );
      if (status = -1) then
      begin
        writeln('readSymbolTable: Unable to seek to symbol table entry ',entryId);
      end;
      status := FileRead( theFile.handle, symbolentry, SZCOFFSYMENT );
      if (status = -1) then
      begin
        writeln('readSymbolTable: Unable to read symbolentry#',entryId);
      end;
      if (status <> SZCOFFSYMENT) then
      begin
        writeln('readSymbolTable: Could not read complete data for symbolentry#',entryId,', only ',status,' bytes read');
      end;

      symbolname := getSymbolName( theFile, entryId );

      write( theFile.fout, IntToHex( entryId, 3 ), ' ' );
      write( theFile.fout, IntToHex( symbolentry.n_value, 8 ), ' ' );
      case symbolentry.n_scnum of
   -2:  write( theFile.fout, 'DEBUG' );
   -1:  write( theFile.fout, 'ABS  ' );
    0:  write( theFile.fout, 'UNDEF' );
      else
        write( theFile.fout, 'SECT',IntToHex( symbolentry.n_scnum, 1 ) );
      end;

      write( theFile.fout, ' ', decodeSymbolTypeMSB( symbolentry.n_type ) );
      write( theFile.fout, ' ', decodeSymbolTypeLSB( symbolentry.n_type ) );
      write( theFile.fout, ' ', decodeSymbolClass( symbolentry.n_sclass ) );
      write( theFile.fout, ' | ',symbolname );
      writeln( theFile.fout );

      // are there any auxiliary records supporting this symbol entry?
      if (symbolentry.n_numaux > 0) then
      begin
        // Does this auxiliary record describe the source file name?
        if (symbolentry.n_sclass = IMAGE_SYM_CLASS_FILE) then
        begin
          // yes, so there may be a number of auxiliary records depending on filename length
          filename := '';
          for i := 1 to symbolentry.n_numaux do
          begin
            auxentryId := entryId + i;
            // ensure we jump to the correct auxiliary symbolentry
            status := FileSeek( theFile.handle, theFile.header.f_symptr + auxentryId*SZCOFFSYMENT, fsFromBeginning );
            if (status = -1) then writeln( 'readSymbolTable: Unable to jump to file auxiliary entry ', auxentryId );
            // read the auxiliary entry
            status := FileRead( theFile.handle, fileentry, SZCOFFSYMENT );
            if (status = -1) then writeln( 'readSymbolTable: Unable to read the filename auxiliary entry#', auxentryId );
            if (status <> SZCOFFSYMENT) then writeln( 'readSymbolTable: Could not read complete data for filename auxiliary entry#', auxentryId, ', only ', status, ' bytes read' );

            for j := 0 to (SZCOFFAUXSCN - 1) do
            begin
              // only accept ASCII text char values (i.e. space..~)
              if (31 < fileentry.x_filename[j]) and (fileentry.x_filename[j] < 127) then
              begin
                filename := filename + chr(fileentry.x_filename[j]);
              end;
            end;
          end;
          writeln( theFile.fout, '    ', filename );
        end
        else
        begin
          // ensure we jump to the auxiliary symbolentry
          auxentryId := entryId + 1;
          status := FileSeek( theFile.handle, theFile.header.f_symptr + auxentryId*SZCOFFSYMENT, fsFromBeginning );
          if (status = -1) then writeln( 'readSymbolTable: Unable to jump back to symbol table entry ', auxentryId );
          // read the auxiliary entry
          // should really take into account the prior symbol entry data
          // as to the expected auxiliary record format
          status := FileRead( theFile.handle, auxentry, SZCOFFSYMENT );
          if (status = -1) then writeln( 'readSymbolTable: Unable to read auxiliaryentry#', auxentryId );
          if (status <> SZCOFFSYMENT) then writeln( 'readSymbolTable: Could not re-read complete data for auxiliaryentry#', auxentryId, ', only ', status, ' bytes read' );

          write( theFile.fout, '   ' );
          write( theFile.fout, ' Section length ', IntToHex( auxentry.x_scnlen, 8 ), ',' ); // section length
          write( theFile.fout, ' #relocs ',     IntToHex( auxentry.x_nreloc, 4 ), ',' ); // number of relocations
          write( theFile.fout, ' #linenums ',    IntToHex( auxentry.x_nlnno, 4 ), ',' );     // number of line numbers
          write( theFile.fout, ' checksum ',     IntToHex( auxentry.x_chsum, 8 ) );      // COMDAT checksum
//          write( theFile.fout, ' Section#: ',   IntToHex( auxentry.x_secno, 4 ) );    // COMDAT section number
//          write( theFile.fout, ' Section#: ',   IntToHex( auxentry.x_selno, 4 ) );    // COMDAT selection number
          writeln( theFile.fout );
        end;
      end;

      // ok, auxiliary records read, now for the next symbol entry
      if (symbolentry.n_numaux > 0) then
      begin
        // skip the auxiliary symbol entry (for the moment)
        entryId := entryId + symbolentry.n_numaux + 1;
      end
      else
      begin
        entryId := entryId + 1;
      end;

      flush( theFile.fout );
    end;

  end;

  function getLongInt( var theFile : tCoffFile; rawdataptr : longint; rawoffset : longint ): longint;
  var
    status : longint;
    d : longint;
  begin
    status := FileSeek( theFile.handle, rawdataptr + rawoffset, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('getLongInt: Unable to seek rawdata at offset ', rawoffset );
    end;
    status := FileRead( theFile.handle, d, 4 );
    if (status = -1) then
    begin
      writeln('getLongInt: Unable to read raw data to be relocated at file offset ',IntToHex(rawdataptr + rawoffset,8));
    end;
    if (status <> 4) then
    begin
      writeln('getLongInt: Could not read complete data for rawdata at file offset ',IntToHex(rawdataptr + rawoffset,8),' only ',status,' bytes read');
    end;

    getLongInt := d;
  end;

  procedure traverseRawLine( var theFile : tCoffFile; sectionId : integer; id : integer; offset : longint; size : integer );
  var
    status : longint;
    rawdata : array [0..15] of char;
    i,j : integer;
  begin
    status := FileSeek( theFile.handle, offset, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('traverseRawLine: Unable to seek rawdata for section# ',sectionId);
    end;
    status := FileRead( theFile.handle, rawdata, size);
    if (status = -1) then
    begin
      writeln('traverseRawLine: Unable to read section ',sectionId);
    end;
    if (status <> size) then
    begin
      writeln('traverseRawLine: Could not read raw data line for section# ',sectionId,', only ',status,' bytes read');
    end;

    write( theFile.fout, '  ', IntToHex( (id - 1)*16, 8 ), ':' );
    for i := 1 to size do
    begin
      write( theFile.fout, ' ',charToHex( rawdata[ i - 1 ] ) );
    end;
    if size < 16 then
    begin
      for i := size + 1 to 16 do write( theFile.fout, '   ' );
    end;
    write( theFile.fout, ' ');
    for i := 1 to size do
    begin
      j := ord ( rawdata[ i - 1 ] );
      if (31 < j) and (j < 127) then
      begin
        write( theFile.fout, rawdata[ i - 1 ] );
      end
      else
      begin
        write( theFile.fout, '.' );
      end;
    end;
    writeln( theFile.fout );
    
    flush( theFile.fout );
  end;

  procedure traverseSectionRawData( var theFile : tCoffFile; sectionId : integer; offset : longint; size : longint );
  var
    i,n : integer;
  begin
    // read the rawdata in chunks of 16 bytes
    n := size div 16;
    writeln( theFile.fout, 'RAWDATA#',IntToHex( sectionId, 4 ) );
    for i := 1 to n do
    begin
      traverseRawLine( theFile, sectionId, i, offset + (i - 1)*16, 16 );
    end;
    // don't forget any remainder of rawdata bytes
    if (size > 16*n) then
    begin
      traverseRawLine( theFile, sectionId, n + 1, offset + n*16, size - (16*n) );
    end;
  end;

  procedure traverseSectionRelocation( var theFile : tCoffFile; sectionId : integer; offset : longint; id : integer; rawdataptr : longint );
  var
    status : longint;
    relocation : coffreloc;
    s : string;
  begin
    status := FileSeek( theFile.handle, offset, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('traverseSectionRelocation: Unable to seek relocation# ',id,' for section# ',sectionId);
    end;

    status := FileRead( theFile.handle, relocation, SZCOFFRELOC );
    if (status = -1) then
    begin
      writeln('traverseSectionRelocation: Unable to read relocation#',id,' for section ',sectionId);
    end;
    if (status <> SZCOFFRELOC) then
    begin
      writeln('traverseSectionRelocation: Could not read complete data for relocation#',id,' for section# ',sectionId,', only ',status,' bytes read');
    end;

    s := decodei386RelocationType( relocation.r_type );
    write( theFile.fout, ' ',IntToHex( relocation.r_vaddr, 8) );  // (virtual) address of reference
    write( theFile.fout, '  ',s,' ':(16 - length(s)) );   // relocation type
    write( theFile.fout, ' ':11,IntToHex( getLongInt( theFile, rawdataptr, relocation.r_vaddr ), 8 ), ' ':2); // value to be amended
    write( theFile.fout, IntToHex( relocation.r_symndx, 8 ):8 ); // index into symbol table

    write( theFile.fout, '  ', getSymbolName( theFile, relocation.r_symndx ) );
    writeln( theFile.fout );
  end;

  procedure traverseSectionRelocations( var theFile : tCoffFile; sectionId : integer; offset : longint; count : word; rawdataptr : longint );
  var
    i : integer;
  begin
    writeln( theFile.fout );
    writeln( theFile.fout, 'RELOCATIONS #',IntToHex(sectionId,4) );
    writeln( theFile.fout, '                                                Symbol    Symbol' );
    writeln( theFile.fout, ' Offset    Type              Applied To         Index     Name' );
    writeln( theFile.fout, ' --------  ----------------  -----------------  --------  ------' );

    for i := 1 to count do
    begin
      traverseSectionRelocation( theFile, sectionId, offset + (i-1)*SZCOFFRELOC, i, rawdataptr );
    end;

    flush( theFile.fout );
  end;

  procedure traverseSectionLineNumber( var theFile : tCoffFile; sectionId : integer; offset : longint; id : integer );
  var
    status : longint;
    coffline : cofflineno;
  begin
    status := FileSeek( theFile.handle, offset, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('traverseSectionLineNumber: Unable to seek lineno# ',id,' for section# ',sectionId);
    end;

    status := FileRead( theFile.handle, coffline, SZCOFFLINENO );
    if (status = -1) then
    begin
      writeln('readOneLineNumber: Unable to read lineno#',id,' for section ',sectionId);
    end;
    if (status <> SZCOFFLINENO) then
    begin
      writeln('traverseSectionLineNumber: Could not read complete data for lineno#',id,' for section# ',sectionId,', only ',status,' bytes read');
    end;

    write( theFile.fout, IntToHex( coffline.l_addr.l_paddr, 8 ),'(',coffline.l_lnno:5,')' );  // (virtual) address of lineno
  end;

  procedure traverseSectionLineNumbers( var theFile : tCoffFile; sectionId : integer; offset : longint; count : word );
  var
    i : integer;
  begin
    writeln( theFile.fout );
    writeln( theFile.fout , 'LINENUMBERS #',IntToHex(sectionId,4) );
    for i := 1 to count do
    begin
      traverseSectionLineNumber( theFile, sectionId, offset + (i-1)*SZCOFFLINENO, i );
      if (i = 4*(i div 4)) then
      begin
        writeln( theFile.fout );
        flush( theFile.fout );
      end;
    end;
    if (count > 4*(i div 4)) then
    begin
      writeln( theFile.fout );
      flush( theFile.fout );
    end;
  end;

  procedure traverseSection( var theFile : tCoffFile; sectionId : integer );
  var
    status : longint;
    section : coffscnhdr;
    i : integer;
    name, mainname, subname : string;
  begin
    writeln( theFile.fout );

    status := FileSeek( theFile.handle, SZFILEHDR + (sectionId - 1)*SZSECHDR, fsFromBeginning );
    if (status = -1) then
    begin
      writeln('traverseSection: Unable to seek section ',sectionId);
    end;

    status := FileRead( theFile.handle, section, SZSECHDR);
    if (status = -1) then
    begin
      writeln('traverseSection: Unable to read section ',sectionId);
    end;
    if (status <> SZSECHDR) then
    begin
      writeln('traverseSection: Could not read complete section ',sectionId,' only ',status,' bytes read');
    end;

    name := '';
    for i := 0 to SYMNMLEN - 1 do
    begin
      if section.s_name[i] <> chr(0) then
      begin
        name := name + section.s_name[i];
      end;
    end;

    writeln( theFile.fout, 'Section#: ',IntToHex(sectionId,4));
    write( theFile.fout, '    Name: ', name);
    if (pos( '/', name) = 1) then
    begin
      // Looks like a Free Pascal Coff .o object file
      // This section likely describes a single procedure/function
      i := StrToInt( copy( name, 2, length(name) - 1 ) );
      write( theFile.fout, '  (', getStringEntry( theFile, i ), ')' );
    end;
    writeln( theFile.fout );

    subname := '';
    mainname := name;
    if pos( '$', name ) > 0 then
    begin
      subname := copy( name, pos( '$', name ) + 1, length( name ) - pos( '$', name ) );
      mainname := copy( name , 1 , pos( '$', name ) - 1 );
    end;
    case mainname of
'.bss':
      begin
        if (subname <> '') then
        begin
          writeln( theFile.fout, ' Section defines UNINITIALISED DATA grouped by ',subname);
        end
        else
        begin
          writeln( theFile.fout, ' Section defines UNINITIALISED DATA' );
        end;
      end;
'.data':
      begin
        if (subname <> '') then
        begin
          writeln( theFile.fout, ' Section defines READ/WRITE DATA grouped by ',subname);
        end
        else
        begin
          writeln( theFile.fout, ' Section defines READ/WRITE DATA' );
        end;
      end;
'.debug':
      begin
        if (subname <> '') then
        begin
          writeln( theFile.fout, ' Section defines DEBUG DATA grouped by ',subname);
        end
        else
        begin
          writeln( theFile.fout, ' Section defines DEBUG DATA' );
        end;
      end;
'.drectve':
      begin
        writeln( theFile.fout, ' Section defines DIRECTIVE' );
      end;
'.rdata':
      begin
        if (subname <> '') then
        begin
          writeln( theFile.fout, ' Section defines INITIALISED DATA grouped by ',subname);
        end
        else
        begin
          writeln( theFile.fout, ' Section defines INITIALISED DATA' );
        end;
      end;
'.text':
      begin
        if (subname <> '') then
        begin
          writeln( theFile.fout, ' Section defines CODE grouped by ',subname);
        end
        else
        begin
          writeln( theFile.fout, ' Section defines CODE' );
        end;
      end;
'_ITRAP':
      begin
        case subname of
    'B':  begin
            theFile.mainprog := true;
            writeln( theFile.fout, ' Section defines PROGRAM TRAP' );
          end;
    'D':  writeln( theFile.fout, ' Section defines ROUTINE TRAP' );
    'F':  writeln( theFile.fout, ' Section defines END TRAP' );
        else
          writeln( theFile.fout, ' Section defines TRAP' );
        end;
      end;
'_SWTAB':
      begin
        writeln( theFile.fout, ' Section defines SWITCH TABLE' );
      end;
    else
      writeln( theFile.fout, ' Section defines unknown entity' );
    end;

    writeln( theFile.fout, 'PhysicalAddr: ', IntToHex( section.s_paddr,8 ) );       // physical address
    writeln( theFile.fout, ' VirtualAddr: ', IntToHex( section.s_vaddr,8 ) );       // virtual address
    writeln( theFile.fout, ' SectionSize: ', IntToHex( section.s_size, 8 ) );       // section size
    writeln( theFile.fout, '  DataOffset: ', IntToHex( section.s_scnptr,8));        // file ptr to raw data
    writeln( theFile.fout, ' RelocOffset: ', IntToHex( section.s_relptr, 8 ) );     // file pointer to relocation list
    writeln( theFile.fout, 'LineNoOffset: ', IntToHex( section.s_lnnoptr, 8 ) );    // file point to line numbers
    writeln( theFile.fout, '     #Relocs: ', IntToHex( section.s_nreloc, 8) );      // number of relocations
    writeln( theFile.fout, '    #LineNos: ', IntToHex( section.s_nlnno, 4 ) );      // number of line numbers
    writeln( theFile.fout, 'SectionFlags: ', IntToHex(section.s_flags, 8 ) );       // section flags
    writeln( theFile.fout, '             ',  decodeSectionFlags(section.s_flags) ); // section flags
    flush( theFile.fout );

    traverseSectionRawData( theFile, sectionId, section.s_scnptr, section.s_size );
    if (section.s_nreloc > 0) then
    begin
      traverseSectionRelocations( theFile, sectionId, section.s_relptr, section.s_nreloc, section.s_scnptr );
    end;
    if (section.s_nlnno > 0) then
    begin
      traverseSectionLineNumbers( theFile, sectionId, section.s_lnnoptr, section.s_nlnno );
    end;
  end;

  procedure traverseSections( var theFile : tCoffFile );
  var
    i : integer;
  begin
    if (theFile.header.f_nscns > 0) then
    begin
      for i := 1 to theFile.header.f_nscns do
      begin
        traverseSection( theFile, i );
      end;
    end;
  end;

  procedure traverseFile( var theFile : tCoffFile );
  var
    timdat : qword;
  begin
    timdat := theFile.header.f_timdat;

	writeln( theFile.fout, '      Magic: ', IntToHex( theFile.header.f_magic, 4 ),' == ', decodeMagicNumber( theFile.header.f_magic ) );    // magic number
    writeln( theFile.fout, '    FileAge: ', IntToHex( FileAge( theFile.name ), 8 ),' == ', DateTimeToStr( FileDateToDateTime( FileAge( theFile.name ) ) ) ); // time and date stamp
    writeln( theFile.fout, '   FileDate: ', IntToHex( theFile.header.f_timdat, 8 ), ' == ', DateTimeToStr( UnixToDateTime( timdat ) ) ); // time and date stamp
    writeln( theFile.fout, '      Flags: ', IntToHex( theFile.header.f_flags, 4 ), ' == ', decodeHeaderFlags(theFile.header.f_flags) ); // flags
    writeln( theFile.fout, '   OptHdrSz: ', IntToHex( theFile.header.f_opthdr, 4 ),' == ',theFile.header.f_opthdr);
	writeln( theFile.fout, '  #Sections: ', IntToHex( theFile.header.f_nscns, 4 ) );    // number of sections
    writeln( theFile.fout, '    SymTab@: ', IntToHex( theFile.header.f_symptr, 8 ) );
    writeln( theFile.fout, '    #SymTab: ', IntToHex( theFile.header.f_nsyms, 8) );
    writeln( theFile.fout, ' StringTab@: ', IntToHex( theFile.strTabPtr, 8 ) );
    writeln( theFile.fout, 'StringTabSz: ', IntToHex( theFile.strTabSz, 2 ) );
    flush( theFile.fout );

    traverseSections( theFile );
    traverseSymbolTable( theFile );
  end;

  procedure readCoff( infilename, outfilename : string );
  var
    status : longint;
    thefile : tCoffFile;
  begin
    thefile.name := infilename;
    { open the object file (as a binary random access file, readonly) }
    thefile.handle := FileOpen( thefile.name, fmOpenRead+fmShareExclusive );
    { quit if we couldn't access the file for whatever reason }
    if (thefile.handle = -1) then
    begin
      writeln('readCoff: Can''t open input COFF file: ',thefile.name );
      Halt( 1 );
    end;

    status := FileRead( thefile.handle, thefile.header, SZFILEHDR );
    if (status = -1) then
    begin
      writeln('readCoff: Unable to read FileHeader');
    end;

    (* Now to setup required derived values *)
    (* First where is the string table *)
    theFile.strtabptr := theFile.header.f_symptr + theFile.header.f_nsyms*SZCOFFSYMENT;
    (* Now to find out the string table size *)
    status := FileSeek( theFile.handle, theFile.strTabPtr, fsFromBeginning );
    if (status = -1) then
    begin
      writeln( 'readCoff: Unable to access string table!');
    end;
    status := FileRead( theFile.handle, theFile.strTabSz, 2 ); // read the string table size (limited to 2^16 bytes *)
    if (status = -1) then
    begin
      writeln( 'readCoff: Unable to read string table size');
    end;
    if (status <> 2) then
    begin
      writeln( 'readCoff: Could not read word containing string table size. Only ',status,' bytes read');
    end;

    { open the list file }
    assign( theFile.fout, outfilename );
    rewrite( theFile.fout );

    traverseFile( theFile );

    close( theFile.fout );
    FileClose( theFile.handle );
  end;

  procedure help();
  begin
    writeln('COFF2DUMP: Version ',version);
    writeln('COFF2DUMP: 2 parameters expected: coff2dump [obj file] [list file]');
  end;

begin
  if (ParamCount = 2) then
  begin
    if fileExists( ParamStr( 1 ) ) then
    begin
      readcoff( ParamStr( 1 ), ParamStr( 2 ) );
    end
    else
    begin
      writeln( ' Input File ',ParamStr(1),' does not exist!' );
      writeln( ' So program aborted' );
      writeln();
      help();
    end;
  end
  else
  begin
    help();
  end;

end.
