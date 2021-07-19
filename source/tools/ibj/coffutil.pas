{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit coffutil;
interface
uses
  sysutils;

  procedure noteSourceName( s : string );
  procedure formSourceFileName( inname : string );
  procedure initialiseSections();
  procedure incrementSymbolCount();
  procedure incrementRelocsCount();
  procedure incrementSectionSize( segmentId : integer; delta : longint );
  procedure setMainProg();
  function getSectionId( sectionId : integer ): integer;
  function getSymbol( sectionId : integer ): integer;
  function getFirstUserSymbol(): integer;
  procedure initcoff( output : longint );
  procedure putsectionsymbols( output : longint );
  procedure puttraptable( output : longint );
  procedure putlinenumbers( output : longint );
  procedure putexternalspecs( output : longint );
  procedure putexternaldefs( output : longint );
  procedure putstringtable( output : longint );

implementation
uses
  dateutils,
  coffdefs,
  writebig,
  lineutil,
  specutil,
  itemutil,
  stackfixutil,
  labelutil,
  nameutil,
  ibjdef,
  sectDef;

const
  // directives that we'd like to pass on to the Microsoft linker...
  directive = '-defaultlib:LIBI77 ';

  SZDIRECTIVE = length(directive); // we skip the trailing zero

  // set up the data structures for the COFF file
  // we are going to have one file header, then five section headers
  // for each of code, const, data, switch table and trap data, plus
  // a sixth dummy section for the trap table end if we happen to be
  // a main program.
  // The sections are going to be in that order, each directly following
  // the preceding one.  Then there is going to be the relocation list,
  // the line-number list, the symbol table, and the string table (for
  // names longer than 8 chars).

type
  tSection =
  record
    sz  : longint;
    id  : smallint;
    sy  : longint;
    ptr : longint;
  end;

var
  sections : array [cDIRECTIVESECTION..cLINENOSECTION] of tSection;

  filehead    : cofffilehdr;  // COFF file header
  directhead  : coffscnhdr;   // Directive section header
  codehead    : coffscnhdr;   // Code section header
  consthead   : coffscnhdr;   // Constant section header
  datahead    : coffscnhdr;   // Data section header
  swtabhead   : coffscnhdr;   // Switch table section header
  traphead    : coffscnhdr;   // Trap section header
  trapendhead : coffscnhdr;   // Trap end section header (only present for main program)

  symtabOffset : integer; // file offset for the symbol table
  strtaboffset : integer; // file offset for the string table

  auxzeroes  : array [0..17] of byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

  // Pass3 needs to know whether this is a main program or a
  // file of external routines, because main programs get a
  // special symbol defined for the trap table
  mainprog : boolean = false;
  relocsCount : integer = 0;
  symbolCount : longint = 0;
  sectionsCount : word = 0;
  sourceFileName : string;
  firstUserSymbol : integer = 0;

  procedure noteSourceName( s : string );
  begin
    sourceFileName := s;
  end;

  procedure formSourceFileName( inname : string );
  var
    fullName  : string;
  begin
    // in order to get a useful debug output, we try to recreate the input
    // file name by assuming that the intermediate files have the same base
    // name and are in the same directory as the source.
    fullName  := ExpandFileName(inname); // turn it into a full name
    // reform source file name with expanded data
    sourceFileName := ExtractFilePath(fullName) + sourceFileName;
  end;

  // initialise the miscellaneous sections data
  // also whether this object file describes the main program
  // and initialise the count of relocations and id of the first user symbol
  procedure initialiseSections();
  var
    i : smallint;
  begin
    mainProg := false;
    relocsCount := 0;
    symbolCount := 0;
    sectionsCount := 0;

    // Global indices used to plant linker segment size definitions
    for i := cDIRECTIVESECTION to cLINENOSECTION do
    begin
      sections[i].id  := i;
      sections[i].sz  := 0; // initialise the size of the section
      sections[i].sy  := 0;
      sections[i].ptr := 0; // offset pointer (to relocations or lines)
    end;
    // where is the first user symbol
    firstUserSymbol := 0;
  end;

  procedure incrementSymbolCount();
  begin
    // As we build the external symbol table we count them too...
    symbolCount := symbolCount + 1;
  end;

  procedure incrementRelocsCount();
  begin
    relocsCount := relocsCount + 1;
  end;

  procedure incrementSectionSize( segmentId : integer; delta : longint );
  begin
    sections[segmentId].sz := sections[segmentId].sz + delta;
  end;

  function getSectionSize( sectionId : integer ): longint;
  begin
    getSectionSize := sections[sectionId].sz;
  end;

  procedure setMainProg();
  begin
    mainProg := true;
  end;

  function getSectionId( sectionId : integer ): integer;
  begin
    getSectionId := sections[sectionId].id;
  end;

  function getSymbol( sectionId : integer ): integer;
  begin
    getSymbol := sections[sectionId].sy;
  end;

  procedure setSymbol( sectionId : integer; newsy : integer );
  begin
    sections[sectionId].sy := newsy;
  end;

  function getFirstUserSymbol(): integer;
  begin
    getFirstUserSymbol := firstusersymbol;
  end;

  procedure initcoff( output : longint );
  var
    i : smallint;
    sectId : smallint;

    tunix : longint;
    nspecs : integer;
    nlines : integer;
    nreloc : integer;
  begin
    // whats the time now?
    // (convert to Unix time)
    // only remember the low 4 bytes
    tunix := (DateTimeToUnix(now())) and $ffffffff;

    nspecs := getSpecTotal();
    nlines := getLineCount();
    nreloc := relocsCount;

    // Set up the sizes of the miscellaneous sections
    // do it by incrementing the section size
    incrementSectionSize( cDIRECTIVESECTION, SZDIRECTIVE );
    if (mainProg) then
    begin
      incrementSectionSize(cTRAPENDSECTION, 16 );
      // add 2 symbols for the traphead end section
      incrementSymbolCount();
      incrementSymbolCount();
    end;
    incrementSectionSize( cCODERELSECTION,   nreloc * SZRELOC );
    incrementSectionSize( cSWTABRELSECTION,  (getSectionSize( cSWTABSECTION ) div 4) * SZRELOC );
    incrementSectionSize( cTRAPRELSECTION,   (getSectionSize( cTRAPSECTION ) div 8) * SZRELOC );
    incrementSectionSize( cLINENOSECTION,    nlines * SZLINENO );
    // at this point the various section sizes should be determined

    // Now we can set up the real id of the genuine sections
    sectId := 1;
    sections[cDIRECTIVESECTION].id := sectId; sectId := sectId + 1;
    for i := cCODESECTION to cTRAPSECTION do
    begin
      if (getSectionSize(i) <> 0) then
      begin
        sections[i].id := sectId;
        sectId := sectId + 1;
      end
      else
      begin
        sections[i].id := 0;
      end;
    end;
    if (mainprog) then
    begin
      sections[cTRAPENDSECTION].id := sectId;
      sectId := sectId + 1;
    end
    else
    begin
      sections[cTRAPENDSECTION].id := 0;
    end;
    // now thw genuine section index should be determined

    // evaluate the count of sections
    if (getSectionSize( cDIRECTIVESECTION ) <> 0) then sectionsCount := sectionsCount + 1;
    if (getSectionSize( cCODESECTION )      <> 0) then sectionsCount := sectionsCount + 1;
    if (getSectionSize( cCONSTSECTION )     <> 0) then sectionsCount := sectionsCount + 1;
    if (getSectionSize( cDATASECTION )      <> 0) then sectionsCount := sectionsCount + 1;
    if (getSectionSize( cSWTABRELSECTION )  <> 0) then sectionsCount := sectionsCount + 1;
    if (getSectionSize( cTRAPSECTION )      <> 0) then sectionsCount := sectionsCount + 1;
    if (mainProg)                                 then sectionsCount := sectionsCount + 1; // for the dummy trap table end section

    // FileHeader details
    setfile( output, SZFILEHDR + (sectionsCount * SZSECHDR) );
    // The genuine section details
    setsize( cDIRECTIVESECTION, SZDIRECTIVE );
    setsize( cCODESECTION,      getSectionSize( cCODESECTION ) );
    setsize( cCONSTSECTION,     getSectionSize( cCONSTSECTION ) );
    setsize( cDATASECTION,      getSectionSize( cDATASECTION ) );
    setsize( cSWTABSECTION,     getSectionSize( cSWTABSECTION ) );
    setsize( cTRAPSECTION,      getSectionSize( cTRAPSECTION ) );
    setsize( cTRAPENDSECTION,   getSectionSize( cTRAPENDSECTION ) );
    // the pseudo sections, the relocation details + line number details
    setsize( cCODERELSECTION,   getSectionSize( cCODERELSECTION ) );
    setsize( cSWTABRELSECTION,  getSectionSize( cSWTABRELSECTION ) );
    setsize( cTRAPRELSECTION,   getSectionSize( cTRAPRELSECTION ) );
    setsize( cLINENOSECTION,    getSectionSize( cLINENOSECTION ) );

    // Firstly manufacture each of the section headers
    directhead.s_name   := '.drectve';
    directhead.s_paddr  := 0;
    directhead.s_vaddr  := 0;
    directhead.s_size   := getSectionSize( cDIRECTIVESECTION );
    directhead.s_scnptr := SZFILEHDR + (sectionsCount * SZSECHDR);
    directhead.s_relptr := 0;
    directhead.s_lnnoptr:= 0;
    directhead.s_nreloc := 0;
    directhead.s_nlnno  := 0;
    directhead.s_flags  := $00100a00; // as used by MS C

    codehead.s_name     := '.text';
    codehead.s_paddr    := 0;
    codehead.s_vaddr    := 0;
    codehead.s_size     := getSectionSize( cCODESECTION );
    codehead.s_scnptr   := directhead.s_scnptr + directhead.s_size;
    if (nreloc = 0) then
      codehead.s_relptr := 0
    else
      codehead.s_relptr := SZFILEHDR
                         + (sectionsCount * SZSECHDR)
                         + getSectionSize( cDIRECTIVESECTION )
                         + getSectionSize( cCODESECTION )
                         + getSectionSize( cCONSTSECTION )
                         + getSectionSize( cDATASECTION )
                         + getSectionSize( cSWTABSECTION )
                         + getSectionSize( cTRAPSECTION )
                         + getSectionSize( cTRAPENDSECTION );
    codehead.s_lnnoptr  := codehead.s_relptr
                         + getSectionSize( cCODERELSECTION ) 
                         + getSectionSize( cSWTABRELSECTION )
                         + getSectionSize( cTRAPRELSECTION );
    codehead.s_nreloc   := nreloc;
    codehead.s_nlnno    := nlines;
    codehead.s_flags    := $60500020; // readable executable 16 byte aligned code

    consthead.s_name    := '.rdata';
    consthead.s_paddr   := 0;
    consthead.s_vaddr   := 0;
    consthead.s_size    := getSectionSize( cCONSTSECTION );
    consthead.s_scnptr  := codehead.s_scnptr + codehead.s_size;
    consthead.s_relptr  := 0;
    consthead.s_lnnoptr := 0;
    consthead.s_nreloc  := 0;
    consthead.s_nlnno   := 0;
    consthead.s_flags	:= $40300040; // read only 4 byte aligned initialised data

    datahead.s_name     := '.data';
    datahead.s_paddr    := 0;
    datahead.s_vaddr    := 0;
    datahead.s_size     := getSectionSize( cDATASECTION );
    datahead.s_scnptr   := consthead.s_scnptr + consthead.s_size;
    datahead.s_relptr   := 0;
    datahead.s_lnnoptr  := 0;
    datahead.s_nreloc   := 0;
    datahead.s_nlnno    := 0;
    datahead.s_flags    := $C0300040; // read/writable 4 byte aligned initialised data

    swtabhead.s_name    := '_SWTAB';
    swtabhead.s_paddr   := 0;
    swtabhead.s_vaddr   := 0;
    swtabhead.s_size    := getSectionSize( cSWTABSECTION );
    swtabhead.s_scnptr  := datahead.s_scnptr + datahead.s_size;
    swtabhead.s_relptr  := codehead.s_relptr + getSectionSize( cCODERELSECTION );
    swtabhead.s_lnnoptr := 0;
    swtabhead.s_nreloc  := (getSectionSize( cSWTABSECTION ) div 4); // every 32 bit entry is relocated
    swtabhead.s_nlnno   := 0;
    swtabhead.s_flags   := $40300040;                // read only 4 byte aligned initiliased data

    // In order that we can traverse the trap table at run time we want
    // to ensure that our main trap table base is loaded first in the executable image.
    // The COFF linker groups same-name sections in alphabetical order using the token
    // after a $ symbol (the $ and token are then discarded by the linker).
    // Why letters B, D, F and not A,B,C?  In case we ever want to insert some other
    // sections in the sequence...
    if (mainProg) then
      traphead.s_name := '_ITRAP$B'
	else
      traphead.s_name := '_ITRAP$D';
    traphead.s_paddr    := 0;
    traphead.s_vaddr    := 0;
    traphead.s_size     := getSectionSize( cTRAPSECTION );
    traphead.s_scnptr   := swtabhead.s_scnptr + swtabhead.s_size;
    traphead.s_relptr   := swtabhead.s_relptr + getSectionSize( cSWTABRELSECTION );
    traphead.s_lnnoptr  := 0;
    traphead.s_nreloc   := (traphead.s_size div 8); // every 32 byte entry has 4 addresses to be relocated
    traphead.s_nlnno    := 0;
    traphead.s_flags    := $40600040;              // read only 32 byte aligned initialised data

	// the end section will be linked after all other trap tables
    trapendhead.s_name    := '_ITRAP$F';
    trapendhead.s_paddr   := 0;
    trapendhead.s_vaddr   := 0;
    trapendhead.s_size    := getSectionSize( cTRAPENDSECTION );
    trapendhead.s_scnptr  := traphead.s_scnptr + traphead.s_size;
    trapendhead.s_relptr  := 0;         // no relocations - it's just a placeholder
    trapendhead.s_lnnoptr := 0;
    trapendhead.s_nreloc  := 0;
    trapendhead.s_nlnno   := 0;
    trapendhead.s_flags   := $40600040; // read only 32 byte aligned initialised data

	// Now assemble the main file header
    filehead.f_magic  := IMAGE_FILE_MACHINE_I386;
    filehead.f_nscns  := sectionsCount;
    filehead.f_timdat := tunix;  // Time in seconds since Jan 1, 1970 00:00
    filehead.f_symptr := codehead.s_relptr
                         + getSectionSize( cCODERELSECTION ) 
                         + getSectionSize( cSWTABRELSECTION )
                         + getSectionSize( cTRAPRELSECTION )
                         + getSectionSize( cLINENOSECTION );
    filehead.f_nsyms  := symbolCount + nspecs + (sectionsCount*2) + 2 + (length(sourceFileName) div 18) + 1;
    filehead.f_opthdr := 0;
    filehead.f_flags  := 0;

    // where is the string table to go?
    strtaboffset      := filehead.f_symptr + filehead.f_nsyms * SZSYMENT;

    // write the file header first
    FileSeek( output, 0, fsFromBeginning );
    FileWrite( output, filehead, SZFILEHDR );
    // we always have a directive section
    FileWrite( output, directhead, SZSECHDR );
    // now for the optional sections
    if (getSectionSize( cCODESECTION )  <> 0) then FileWrite( output, codehead, SZSECHDR );
    if (getSectionSize( cCONSTSECTION ) <> 0) then FileWrite( output, consthead, SZSECHDR );
    if (getSectionSize( cDATASECTION )  <> 0) then FileWrite( output, datahead, SZSECHDR );
    if (getSectionSize( cSWTABSECTION ) <> 0) then FileWrite( output, swtabhead, SZSECHDR );
    if (getSectionSize( cTRAPSECTION )  <> 0) then FileWrite( output, traphead, SZSECHDR );
    if (mainProg)                             then FileWrite( output, trapendhead, SZSECHDR );

    // since it's not really part of anything else useful, we output
    // the linker directive now...
    for i := 1 to SZDIRECTIVE do writebyte( cDIRECTIVESECTION, ord(directive[i]) );

    // and similarly we put 16 bytes of zeroes into the trapend section
    for i := 1 to trapendhead.s_size do writebyte( cTRAPENDSECTION, 0 );
  end;

  // Output the dummy symbols in the symbol table for the filename and for each section
  procedure putsectionsymbols( output : longint );
  var
    sym : coffsyment;
    aux : coffauxscn;
    sequence, i, count, symbol : integer;
    filename : string;
    symptr : longint;
  begin
    filename := sourceFileName;
    symptr := filehead.f_symptr;

    // the first pseudo-symbol is the source filename, which we've stored in path_buffer
    count := (length(filename) + 18) div 18; // this is how many 18 byte aux records that will take

    sym.n.n_n.n_offset := 0; // to make sure we get a clean name
    sym.n.n_name := '.file';
    sym.n_scnum  := -2;	     // special debug entry
    sym.n_value  := 0;       // no value
    sym.n_type   := 0;       // no type
    sym.n_sclass := 103;     // a filename
    sym.n_numaux := count;   // the number of auxiliary records we're using

    FileSeek( output, symptr, fsFromBeginning);
    FileWrite( output, sym, SZSYMENT );
    FileFlush( output );

    symptr := symptr + SZSYMENT;

    // now write the filename, padding the last 18 bytes with zeroes
    FileSeek( output, symptr, fsFromBeginning);
    for i := 1 to length(filename) do
    begin
      filewrite( output, filename[i], 1 );
    end;
    FileWrite( output, auxzeroes, count * 18 - length(filename) );
    FileFlush( output );

    // increment the symbol count in the file header
    symptr := symptr + count * SZSYMENT;

    // The next symbol we write out is the mysterious COMP.ID symbol.
    // Why?  I have no idea, but Microsoft tools like to find this....
    sym.n.n_name := '@comp.id';
    sym.n_scnum  := -1;	     // special absolute entry
    sym.n_value  := $151FE8; // mystery value
    sym.n_type   := 0;       // no type
    sym.n_sclass := 3;       // static
    sym.n_numaux := 0;       // no aux record

    FileSeek( output, symptr, fsFromBeginning);
    FileWrite( output, sym, SZSYMENT );
    FileFlush( output );

    symptr := symptr + SZSYMENT;

	// OK - the next symbol we will output is going to be...
	symbol := count + 2;

    // set up all the common elements of a section symbol
    sym.n_value  := 0; // zero (section base)
    sym.n_type   := 0; // NOT a function
    sym.n_sclass := 3; // static
    sym.n_numaux := 1; // each has one auxilliary

    aux.x_chsum  := 0; // we don't checksum the sections
    aux.x_secno  := 0;
    aux.x_selno  := 0;
    aux.x_pad    := 0;

    sequence := 1;

    // directive first
    sym.n.n_n.n_offset := 0; // to make sure we get a clean name
    sym.n.n_name := '.drectve';
    sym.n_scnum  := sequence;

    FileSeek( output, symptr, fsFromBeginning);
    FileWrite( output, sym, SZSYMENT );
    FileFlush( output );

    symptr := symptr + SZSYMENT;

    aux.x_scnlen := SZDIRECTIVE;
    aux.x_nreloc := 0;
    aux.x_nlnno  := 0;

    FileSeek( output, symptr, fsFromBeginning);
    FileWrite( output, aux, SZSYMENT );
    FileFlush( output );

    symptr := symptr + SZSYMENT;

    setSymbol( cDIRECTIVESECTION, symbol );
    symbol := symbol + 2;

    // code
    if (codehead.s_size <> 0) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      sym.n.n_name := '.text';
      sequence := sequence + 1;
      sym.n_scnum := sequence;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, sym, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      aux.x_scnlen := codehead.s_size;
      aux.x_nreloc := relocsCount;
      aux.x_nlnno  := getLineCount();

      FileSeek( output, symptr, fsFromBeginning);
      filewrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cCODESECTION, symbol );
      symbol := symbol + 2;
    end;

    // const
    if (consthead.s_size <> 0) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      sym.n.n_name := '.rdata';
      sequence := sequence + 1;
      sym.n_scnum := sequence;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, sym, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      aux.x_scnlen := consthead.s_size;
      aux.x_nreloc := 0;
      aux.x_nlnno  := 0;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cCONSTSECTION, symbol );
      symbol := symbol + 2;
    end;

    // data
    if (datahead.s_size <> 0) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      sym.n.n_name := '.data';
      sequence     := sequence + 1;
      sym.n_scnum  := sequence;
      FileSeek( output, symptr, fsFromBeginning);
      filewrite( output, sym, SZSYMENT );
      symptr := symptr + SZSYMENT;

      aux.x_scnlen := datahead.s_size;
      aux.x_nreloc := 0;
      aux.x_nlnno  := 0;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cDATASECTION, symbol );
      symbol := symbol + 2;
    end;

    // switch
    if (swtabhead.s_size <> 0) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      sym.n.n_name := '_SWTAB';
      sequence := sequence + 1;
      sym.n_scnum := sequence;

      FileSeek( output, symptr, fsFromBeginning);
      filewrite( output, sym, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      aux.x_scnlen := swtabhead.s_size;
      aux.x_nreloc := swtabhead.s_size div 4;
      aux.x_nlnno  := 0;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cSWTABSECTION, symbol );
      symbol := symbol + 2;
    end;

    // trap
    if (traphead.s_size <> 0) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      if (mainProg) then
        sym.n.n_name := '_ITRAP$B'
      else
        sym.n.n_name := '_ITRAP$D';
      sequence := sequence + 1;
      sym.n_scnum := sequence;
      FileSeek( output, symptr, fsFromBeginning);
      filewrite( output, sym, SZSYMENT );
      symptr := symptr + SZSYMENT;

      aux.x_scnlen := traphead.s_size;
      aux.x_nreloc := traphead.s_size div 8;
      aux.x_nlnno := 0;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cTRAPSECTION, symbol );
      symbol := symbol + 2;
    end;

    // trap end
    if (mainProg) then
    begin
      sym.n.n_n.n_offset := 0; // to make sure we get a clean name
      sym.n.n_name := '_ITRAP$F';
      sequence := sequence + 1;
      sym.n_scnum := sequence;
      FileSeek( output, symptr, fsFromBeginning);
      filewrite( output, sym, SZSYMENT );
      symptr := symptr + SZSYMENT;

      aux.x_scnlen := 16;
      aux.x_nreloc := 0;
      aux.x_nlnno := 0;

      FileSeek( output, symptr, fsFromBeginning);
      FileWrite( output, aux, SZSYMENT );
      FileFlush( output );

      symptr := symptr + SZSYMENT;

      setSymbol( cTRAPENDSECTION, symbol );
      symbol := symbol + 2;
    end;

    firstusersymbol := symbol; // this is where the program symbol table will start
    if (mainprog) then         // plus an extra two for the trap table limits if needed
    begin
      firstusersymbol := firstusersymbol + 2;
    end;

    symtaboffset := symptr;
  end;

  procedure puttraptable( output : longint );
  var
    traplabelPtr    : integer;
    fromlabelPtr    : integer;
	i, j, addr : integer;
	sym : coffsyment;
    name : string;
    temp1 : longint;
    temp2 : longint;
    temp3 : longint;
    temp4 : longint;
  begin
    // for each stack fix item
    for i := 1 to getStackFixCount() do
    begin
      traplabelPtr := findlabel( getStackFixField(i,cStackFixTrap) );
      fromlabelPtr := findlabel(getStackFixField(i,cStackFixEvFrom));

      temp1 := getStackFixField(i,cStackFixStart);
      temp2 := getStackFixField(i,cStackFixEndFn);
      // trap and evfrom are actually labels, so we look them up
      temp3 := getLabelAddress(traplabelPtr);
      temp4 := getLabelAddress(fromlabelPtr);

      writew32( cTRAPSECTION, temp1 ); // address 1
      writew32( cTRAPSECTION, temp2 ); // address 2
      writew32( cTRAPSECTION, temp3 ); // address 3
      writew32( cTRAPSECTION, temp4 ); // address 4

      writew16( cTRAPSECTION, getStackFixField(i,cStackFixEvents) );

      name := getNameString( getStackFixField(i,cStackFixNameId) );

      for j := 1 to 14 do
      begin
        if (j <= length(name)) then
        begin
          writebyte( cTRAPSECTION, ord(name[j]) );
        end
        else
        begin
          writebyte( cTRAPSECTION, 0 );
        end;
      end;

      // Of course the four code addresses we've just planted - start/end/entry/from - all
      // need to be relocated by the beginning of the code segment, so we do four
      // relocation records next...
      addr := 32*(i - 1); // address of first words to relocate is (i - 1)*32
      for j := 0 to 3 do
      begin
        writew32( cTRAPRELSECTION, addr + 4*j );          // offset in section of word to relocate
        writew32( cTRAPRELSECTION, getSymbol(cCODESECTION) ); // symbol index for .text
        writew16( cTRAPRELSECTION, 6 );                       // relocate by actual 32 bit address
      end;
    end;

    // if this was the main program file, we define a symbol that
    // corresponds to the base of the trap table, and one at the end.
    if (mainProg) then
    begin
      i := newname( '__imptrapbase' );
      setNameUsed(i);
      addNameToDictionary(i);

      sym.n.n_n.n_zeroes := 0;
      sym.n.n_n.n_offset := getNameDict(i);
      sym.n_value  := 0;           // first address of this section
      sym.n_scnum  := getSectionId( cTRAPSECTION ); // this section ID
      sym.n_type   := 0;           // this is NOT a function
      sym.n_sclass := 2;           // external definition
      sym.n_numaux := 0;           // no auxilliaries

      FileSeek(output, symtaboffset, fsFromBeginning );
      FileWrite(output, sym, SZSYMENT );
      FileFlush( output );

      symtaboffset := symtaboffset + SZSYMENT;

      // and again for the trap end
      i := newname( '__imptrapend' );
      setNameUsed(i);
      addNameToDictionary(i);

      sym.n.n_n.n_zeroes := 0;
      sym.n.n_n.n_offset := getNameDict(i);
      sym.n_value  := 0;           // first address of this section
      sym.n_scnum := getSectionId(cTRAPENDSECTION); // trapend section ID
      sym.n_type   := 0;           // this is NOT a function
      sym.n_sclass := 2;           // external definition
      sym.n_numaux := 0;           // no auxilliaries

      FileSeek(output, symtaboffset, fsFromBeginning );
      FileWrite(output, sym, SZSYMENT );
      FileFlush( output );

      symtaboffset := symtaboffset + SZSYMENT;
    end;

  end;

  procedure putlinenumbers( output : longint );
  var
   i : integer;
  begin
    for i := 0 to getLineCount() - 1 do
    begin
      writew32(cLINENOSECTION, getLineOffset(i));
      writew16(cLINENOSECTION, getLineNo(i));
    end;
  end;

  procedure putexternalspecs( output : longint );
  var
    i,j : integer;
    specIndex : integer;
    ptr : integer;
    sym : coffsyment;
    name : string;
  begin
    specIndex := 1; // pass 2 spec's use 1-based IDs

    for i := 1 to getItemCount() do
    begin
      case getItemField( i, cItemType ) of
IF_REQEXT:
        begin
          if getSpecUsed( specIndex ) then
          begin
            // prepare the symbol data
            ptr := getItemField( i, cItemInfo );
            name := getNameString( ptr );

            sym.n.n_n.n_zeroes := 0;
            sym.n.n_n.n_offset := 0;
            // add the spec name
            if length(name) <= 8 then
            begin
              for j := 1 to length(name) do
              begin
                sym.n.n_name[j - 1] := name[j];
              end;
            end
            else
            begin
              sym.n.n_n.n_offset := getNameDict( ptr );
            end;

            sym.n_value := 0; // zero (undefined)
            sym.n_scnum := 0; // section zero - external

            sym.n_type := $20; // assume this is a function
            if (getSpecIsData(specIndex)) then sym.n_type := 0; // No, it's a data label

            sym.n_sclass := 2; // external
            sym.n_numaux := 0; // no auxilliaries

            // move to next symbol table slot
            FileSeek( output, symtaboffset, fsFromBeginning );
            // write out the symbol
            FileWrite( output, sym, SZSYMENT );
            // flush out the data to the file
            FileFlush( output );

            // work out the position of the next symbol slot
            symtaboffset := symtaboffset + SZSYMENT;
          end;
          specIndex := specIndex + 1;
        end;
      else
      end;
    end;
  end;

  procedure putexternaldefs( output : longint );
  var
    i,j : integer;
    ptr : integer;
    sym : coffsyment;
    name : string;
  begin
    for i := 1 to getItemCount() do
    begin
      case getItemField( i, cItemType ) of
IF_DEFEXTCODE:
        begin
          // prepare the symbol data
          ptr := getItemField( i, cItemInfo );

          sym.n.n_n.n_zeroes := 0;
          sym.n.n_n.n_offset := 0;
          // add the spec name
          name := getNameString( ptr );
          if length(name) <= 8 then
          begin
            for j := 1 to length(name) do
            begin
              sym.n.n_name[j - 1] := name[j];
            end;
          end
          else
          begin
            sym.n.n_n.n_offset := getNameDict( ptr );
          end;

          sym.n_value := getItemField( i, cItemAddress); // address of this item
          sym.n_scnum := getSectionId(cCODESECTION); // section - code

          sym.n_type := $20; // this is a function

          sym.n_sclass := 2; // external
          sym.n_numaux := 0; // no auxilliaries

          // move to next symbol table slot
          FileSeek( output, symtaboffset, fsFromBeginning );
          // write out the symbol
          FileWrite( output, sym, SZSYMENT );
          // flush out the data to the file
          FileFlush( output );

          // work out the position of the next symbol slot
          symtaboffset := symtaboffset + SZSYMENT;
        end;
IF_DEFEXTDATA:
        begin
          // prepare the symbol data
          ptr := getItemField( i, cItemInfo );

          sym.n.n_n.n_zeroes := 0;
          sym.n.n_n.n_offset := 0;
          // add the spec name
          name := getNameString( ptr );
          if length(name) <= 8 then
          begin
            for j := 1 to length(name) do
            begin
              sym.n.n_name[j - 1] := name[j];
            end;
          end
          else
          begin
            sym.n.n_n.n_offset := getNameDict( ptr );
          end;

          sym.n_value := getItemField( i, cItemAddress); // address of this item
          sym.n_scnum := getSectionId(cDATASECTION); // section - data

          sym.n_type := 0; // this is NOT a function

          sym.n_sclass := 2; // external
          sym.n_numaux := 0; // no auxilliaries

          // move to next symbol table slot
          FileSeek( output, symtaboffset, fsFromBeginning );
          // write out the symbol
          FileWrite( output, sym, SZSYMENT );
          // flush out the data to the file
          FileFlush( output );

          // work out the position of the next symbol slot
          symtaboffset := symtaboffset + SZSYMENT;
        end;
      else
      end;

    end;
  end;

  procedure putstringtable( output : longint );
  begin
	FileSeek(output, strtaboffset, fsFromBeginning);

    writeDictionary( output );

    FileFlush( output );
  end;

end.
