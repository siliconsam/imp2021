{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program ibj2coff(input,output);
uses
  dos,
  sysutils,
  ibjdef,
  ibjutil,
  itemutil,
  labelutil,
  stackfixutil,
  nameutil,
  specutil,
  lineutil,
  coffutil,
  sectdef,
  writebig,
  parseutil;

const
  Version = '1.0';

  procedure initialise();
  begin
    initialiseItems();
    initialiseLabels();
    initialiseStackFix();
    initialiseNames();
    initialiseSpecs();
    initialiseLines();

    initialiseSections();
  end;

  // Reset the label list and then do a pass through the data
  // to set up label records.
  procedure initlabels();
  var
    count, cad, i, itemtype, ptr, id : integer;
  begin
    cad := 0;
    initialiseLabels();

    count := getItemCount();

	for i := 1 to count do
    begin
      itemtype := getItemField(i,cItemType);
      setItemField(i, cItemAddress, cad );
      // only increment the .text section with valid .text items
      case itemType of
IF_OBJ,
IF_DATA,
IF_CONST,
IF_DISPLAY,
IF_JUMP,
IF_JCOND,
IF_CALL,
IF_FIXUP,
IF_SETFIX,
IF_REQEXT,
IF_REFLABEL,
IF_BSS,
IF_REFEXT,
IF_SOURCE,
IF_DEFEXTCODE,
IF_DEFEXTDATA,
IF_SWT,
IF_LINE,
IF_ABSEXT:
        begin
          cad := cad + getItemField(i,cItemSize);
        end;

IF_LABEL:
        begin
          id := getItemField(i,cItemInfo);
          ptr := findlabel(id);	// Pass 2 redefines labels sometimes
          if (ptr = 0) then ptr := newlabel();
          setLabelId( ptr, id );
          setLabelAddress( ptr, cad );
        end;
      else
      end;
    end;
  end;

  // Simple routine that tries to "improve" the jumps.
  // It returns "true" if it found an improvement.
  // Unfortunately we need to iterate because every
  // improvement moves all the downstream labels (which
  // may allow further improvement), so this routine
  // is called more than once.
  function improvejumpsizes(): boolean;
  var
    count, i, ptr, distance : integer;
    success : boolean;
  begin
    success := false;
    count := getItemCount();
    for i := 1 to count do
    begin
      case getItemField(i,cItemType) of
IF_JUMP,
IF_JCOND:
        begin
          if (getItemField(i,cItemSize) > 2) then // not already improved!
          begin
            ptr := getItemField(i,cItemInfo); // pick up label id
            ptr := findlabel(ptr);     // get table index
            distance := getLabelAddress(ptr) - (getItemField(i,cItemAddress) + 2);
            if ((-127 < distance) and (distance < 127)) then
            begin
              // this can this be short?
              setItemField(i,cItemSize,2); // make it so
              success := true;         // and tell the world we've done good
            end;
          end;
        end;
      else
      end;
    end;
    improvejumpsizes := success;
  end;

  // run through the database adding up the various segment sizes
  procedure computesizes();
  var
    ptr : integer;
  begin
    for ptr := 1 to getItemCount() do
    begin
      case getItemField(ptr,cItemType) of
IF_OBJ,      // plain object code
IF_DATA,     // dataseg offset word
IF_CONST,    // const seg offset word
IF_DISPLAY,  // display offset word
IF_JUMP,     // unconditional jump to label
IF_JCOND,    // cond jump to label JE, JNE, JLE, JL, JGE, JG
IF_CALL,     // call a label
IF_FIXUP,    // define location for stack fixup instruction
IF_REFEXT,   // external name relative offset code word
IF_REFLABEL, // label reference (== label address)
IF_BSS,      // BSS seg offset word
IF_SWT,      // SWITCH table segment offset code word
IF_ABSEXT:   // external name relative offset code word
        begin
          incrementSectionSize( cCODESECTION, getItemField(ptr,cItemSize) );
        end;

IF_COTWORD:// Constant table word
        begin
          incrementSectionSize( cCONSTSECTION, getItemField(ptr,cItemSize) );
        end;

IF_DATWORD:// Data segment word
        begin
          incrementSectionSize( cDATASECTION, getItemField(ptr,cItemSize) );
        end;

IF_SWTWORD:// switch table entry - actually a label ID
           // so "size" is 16 bit words, but the entries will be 32 bits
        begin
          incrementSectionSize( cSWTABSECTION, 2*getItemField(ptr,cItemSize) );
        end;

      else
        // all other directives don't consume space
      end;
    end;

	// finally, the trap segment will contain one record for
	// every procedure we've found
    incrementSectionSize( cTRAPSECTION, 32*getStackFixCount() );
  end;

  procedure dumpobjectfile( infilename, outfilename : string );
  var
    fout : longint;
  begin
    { create an empty file, ready to write to }
    fout := FileCreate( outfilename );
    { quit if we couldn't create the file for whatever reason }
    if (fout = -1) then
    begin
      writeln(' Can''t open output file: ',outfilename );
      Halt( 1 );
    end;

    formSourceFileName( infileName );

	initcoff(fout);
	putsectionsymbols(fout);

	// reset the line number information
    initialiseLines();

    if not parseIBJFile( infilename, '', cPassCoffWrite, fout, false ) then
    begin
      writeln('Pass2 of the IBJ file ',infilename,' has errors' );
    end;

    // now plant the trap table
    puttraptable(fout);
    // now output the line number records for the debugger
    putlinenumbers(fout);
    // Now the externals
    putexternalspecs(fout);
    putexternaldefs(fout);
    // finally the string table
    putstringtable(fout);

    flushout();

    FileClose( fout );
  end;

  procedure help();
  begin
    writeln('ibj2coff: Version ',version);
    writeln('ibj2coff: 2 parameters expected: ibj2coff [ibj file] [coff object file]');
  end;

begin
  if (ParamCount = 2) then
  begin
    if fileExists( ParamStr( 1 ) ) then
    begin
      initialise();
      if parseIBJFile( ParamStr( 1 ), '', cPassCoffCreate, -1, false ) then
      begin
        (* Input IBJ file has no errors *)
        initlabels();
        while (improvejumpsizes()) do
        begin
          initlabels();
        end;
        computesizes();
        remapspecs();

        formdictionary();
        dumpobjectfile( ParamStr( 1 ), ParamStr( 2 ) );
      end
      else
      begin
        writeln( ' Error detected in Input ibj File ',ParamStr(1) );
        writeln( ' So program aborted' );
      end;
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
