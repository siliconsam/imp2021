{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit parseutil;
interface
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
  writebig;

const
  // This code forms a common framework to read an IBJ file but perform different actions
  // for each IBJ type.
  // The following set of passes over an IBJ file are intermingled
  // This enables an extra IBJ format to be added and relevant action code
  // can be written for each combination of IBJ file passes
  // Some passes are standalone, some only work in combination
  // A program calling the IBJ parser must take care to only call the correct
  // combination of passes.

  // cPassCoffCreate, cPassCoffWrite work together, Create then Write
  cPassCoffCreate   = 1; // pass used to create a data structure for COFF file generation
  cPassCoffWrite    = 2; // pass used to write data to a COFF file

  // cPassAssemble is a standalone pass
  cPassAssemble     = 3; // pass used to convert a .ibj file to a human-readable form

  // cPassCompactRead, cPassCompactWrite work together, Read then Write
  cPassCompactRead  = 4; // pass used to create a data structure used to compact a .ibj file
  cPassCompactWrite = 5; // pass used to write the compacted ibj data structure to a new .ibj file

  function parseIBJFile( infilename, outfilename : string; passId : integer; handle : longint; debug : boolean ): boolean;

implementation

  procedure incrementItemSize( ptr : integer; delta : integer );
  begin
    setItemField(ptr,cItemSize,getItemField(ptr,cItemSize) + delta );
  end;

  function parseIBJFile( infilename, outfilename : string; passId : integer; handle : longint; debug : boolean ): boolean;
  var
    // common pass variables
    fin       : text;
    fout      : text;
    fdebug    : text;
    theType   : integer;
    theData   : string;
    theSize   : integer;
    errorFlag : boolean;
    lineNo    : integer;

    current   : integer;
    fixupId   : integer;
    ptr       : integer;
    value     : integer;
    cad       : integer;

    // ibj parsed data
    code         : string;
    labelNo      : integer;
    sourcelineNo : integer;
    shortdata    : array [1..2] of byte;
    longdata     : array [1..4] of byte;
    name         : string;
    events       : integer;
    trap         : integer;
    evfrom       : integer;
    level        : byte;
    condition    : byte;
    specId       : integer;
    offsetPlusId : integer;
    offset       : longint;

    // pass specific variables
    // cPassCoffCreate variables
    nameId         : integer;
    externalNameId : integer;
    itemPtr        : integer;

    // cPassCoffWrite variables
    i       : integer;
    swtp    : integer;
    jcondop : array [0..9] of byte = ($74, $75, $7F, $7D, $7C, $7E, $77, $73, $72, $76);

    // cPassCompactWrite variables
    objData         : string;
    objFlag         : boolean;
    lineData        : integer;
    lineFlag        : boolean;
    newSpecId       : integer;
    newoffsetPlusId : integer;

    procedure checkSize( expectedSize : integer );
    begin
      if (theSize <> expectedSize) then
      begin
        if debug then
        begin
          writeln(fdebug,'**** ERROR **** @',lineno,': ',ibjName(theType),' - Oops - length screwup!');
        end;
        writeln(       '**** ERROR **** @',lineno,': ',ibjName(theType),' - Oops - length screwup!');
        errorFlag := true;
      end;
    end;

    procedure checkExpectedType();
    begin
      if (getItemField( current, cItemType ) <> theType) then
      begin
        if debug then
        begin
          writeln(fdebug,'**** DEBUG **** mismatch in parse pass2 line#',lineno
                        ,' expected ',ibjName(theType),' found ',ibjName(getItemField( current, cItemIBJType )) );
        end;
        writeln(       '**** DEBUG **** mismatch in parse pass2 line#',lineno
                      ,' expected ',ibjName(theType),' found ',ibjName(getItemField( current, cItemIBJType )) );
      end;
    end;

  begin
    errorFlag := false;
    lineno := 0;

    if debug then
    begin
      assign( fdebug, infilename+'.debug' );
      rewrite( fdebug );
    end;

    case passId of
cPassCoffCreate:
      begin
        assign( fin, infilename );
        reset( fin );

        // assign variables used by both passes
        cad     := 0;
        current := 0; // should be no items present
      end;
cPassCoffWrite:
      begin
        assign( fin, infilename );
        reset( fin );

        // assign variables used by both passes
        cad     := 0;
        current := 0; // start again - to synchronise lineNo v current entries
        swtp    := 0;
      end;
cPassAssemble:
      begin
        assign( fin, infilename );
        reset( fin );

        assign( fout, outfilename );
        rewrite( fout );
      end;
cPassCompactRead:
      begin
        // The 2 passes cPassCompactRead,cPassCompactWrite (with intervening renumbering code)
        // are used to:
        // 1) compress (as much as possible) cases where an OBJ record follows an OBJ record
        // 2) compact the SpecId range by removing any REQEXT which is not referenced
        //    But we use nameId to be semantically equivalent to specId
        //    so, wherever cPassCoffCreate,cPassCoffWrite calls newSpecId,setSpecUsed,getSpecUsed
        //    then cPassCompactRead,cPassCompactWrite calls newName,setNameUsed, getNameUsed instead
        //    between cPassCompactRead and cPassCompactWrite we compact and renumber the nameId values
        //    depending on whether nameId is used (i.e. specId is used)
        // 3) compacting LINE records by eliminating any LINE which is immediately before a LINE record
        //
        // There may be cases where LINE or OBJ records "surround" a REQEXT record which is being removed
        // If this occurs then re-run the compacter program on the newly compacted IBJ file to further
        // compact the IBJ data
        assign( fin, infilename );
        reset( fin );
      end;
cPassCompactWrite:
      begin
        assign( fin, infilename );
        reset( fin );

        assign( fout, outfilename );
        rewrite( fout );

        objFlag := false;
        objData := '';

        lineFlag := false;
        lineData := 0;
      end;
    else
      // validate the passId
      errorFlag := true;
    end;

    (* Now to read the IBJ file until the end of file *)
    while not eof(fin) do
    begin
      (* read the current line and update the count of lines read so far *)
      readirecord( fin, theType, theSize, theData );
      lineNo := lineNo + 1;

      // Code used if knowledge of previous IBJ record is required
      case passId of
cPassCoffCreate:
        begin
        end;
cPassCoffWrite:
        begin
        end;
cPassAssemble:
        begin
        end;
cPassCompactRead:
        begin
        end;
cPassCompactWrite:
        begin
          // This code detects cases where the last OBJ record is detected
          // in a sequence of OBJ records
          if objFlag and (theType <> IF_OBJ) then
          begin
            writeirecord( fout, IF_OBJ, length( objData ) shr 1 , objData );
            objData := '';
            objFlag := false;
          end;

          // This code detects the case where the last LINE record is detected
          // in a sequence of LINE records
          if lineFlag and (theType <> IF_LINE) then
          begin
            writeirecord( fout, IF_LINE, 2, formword(lineData) );
            lineFlag := false;
            lineData := 0;
          end;
        end;
      else
      end;

      if (length(theData) <> 2*theSize) then
      begin
        if debug then
        begin
          writeln(fdebug,'Mismatch in record length @',lineNo);
        end;
        writeln(       'Mismatch in record length @',lineNo);

        errorFlag := true;
      end
      else
      case theType of
IF_OBJ:
        begin
          // plain object code
          code := '';
          for i := 1 to theSize do
          begin
            code := code + chr( readByte( copy(thedata,2*(i-1) + 1, 2 ) ) );
          end;

          case passId of
cPassCoffCreate:
            begin
              // All of these are treated as "object code" for the first pass
              if (getItemField( current,cItemType ) <> IF_OBJ) then current := newitem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, theSize );

              cad := cad + length(code);
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              for i := 1 to length(code) do
              begin
                writebyte( cCODESECTION, ord( code[i] ) );
              end;

              cad := cad + length(code);
            end;
cPassAssemble:
            begin
              write(fout,'IF_OBJ,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              (* defend against too large OBJ records *)
              (* objData must not exceed 256 characters in length == 128 bytes *)
              (* max limit 128 characters == max length 64 bytes for OBJ record *)
              if length(objData) + length(theData) > 128 then
              begin
                // NB objData contains nibbles not bytes
                // but OBJ record size refers to number of bytes
                writeirecord( fout, IF_OBJ, (length( objData ) DIV 2) , objData );
                objData := theData;
                objFlag := true;
              end
              else
              begin
                objData := objData + theData;
                objFlag := true;
              end;
            end;
          else
          end;
        end;

IF_DATA:
        begin
          // dataseg offset word
          checkSize( WORDSIZE );
          longdata[1] := readByte( copy(theData, 1, 2 ) );
          longdata[2] := readByte( copy(theData, 3, 2 ) );
          longdata[3] := readByte( copy(theData, 5, 2 ) );
          longdata[4] := readByte( copy(theData, 7, 2 ) );

          case passId of
cPassCoffCreate:
            begin
              // All of these are treated as "object code" for the first pass
              incrementRelocsCount();
              if (getItemField( current,cItemType) <> IF_OBJ) then current := newitem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );
              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              writebyte( cCODESECTION, longdata[1] );
              writebyte( cCODESECTION, longdata[2] );
              writebyte( cCODESECTION, longdata[3] );
              writebyte( cCODESECTION, longdata[4] );

              writew32( cCODERELSECTION, cad );             // offset in section of word to relocate
              writew32( cCODERELSECTION, getSymbol( cDATASECTION ) ); // symbol for section
              writew16( cCODERELSECTION, 6 );               // relocate by actual 32 bit address

              cad := cad + WORDSIZE;
            end;
cPassAssemble:
            begin
              write(fout,'IF_DATA,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_DATA, theSize, theData );
            end;
          else
          end;
        end;

IF_CONST:
        begin
          // const seg offset word
          checkSize( WORDSIZE );
          longdata[1] := readByte( copy(theData, 1, 2 ) );
          longdata[2] := readByte( copy(theData, 3, 2 ) );
          longdata[3] := readByte( copy(theData, 5, 2 ) );
          longdata[4] := readByte( copy(theData, 7, 2 ) );

          case passId of
cPassCoffCreate:
            begin
              // All of these are treated as "object code" for the first pass
              incrementRelocsCount();
              if (getItemField( current, cItemType ) <> IF_OBJ) then current := newitem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );

              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              writebyte( cCODESECTION, longdata[1] );
              writebyte( cCODESECTION, longdata[2] );
              writebyte( cCODESECTION, longdata[3] );
              writebyte( cCODESECTION, longdata[4] );

              writew32( cCODERELSECTION, cad );              // offset in section of word to relocate
              writew32( cCODERELSECTION, getSymbol( cCONSTSECTION ) ); // symbol for section
              writew16( cCODERELSECTION, 6 );                // relocate by actual 32 bit address

              cad := cad + WORDSIZE;
            end;
cPassAssemble:
            begin
              write(fout,'IF_CONST,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_CONST, theSize, theData );
            end;
          else
          end;
        end;

IF_DISPLAY:
        begin
          // display seg offset word
          checkSize( WORDSIZE );
          longdata[1] := readByte( copy(theData, 1, 2 ) );
          longdata[2] := readByte( copy(theData, 3, 2 ) );
          longdata[3] := readByte( copy(theData, 5, 2 ) );
          longdata[4] := readByte( copy(theData, 7, 2 ) );

          case passId of
cPassCoffCreate:
            begin
              // All of these are treated as "object code" for the first pass
              incrementRelocsCount();
              if (getItemField( current, cItemType ) <> IF_OBJ) then current := newitem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );
              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              // DISPLAY should have been converted to OBJ
              if (getItemField( current, cItemType ) <> IF_OBJ) then current := current + 1;
            end;
cPassAssemble:
            begin
              write(fout,'IF_DISPLAY,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_DISPLAY, theSize, theData );
            end;
          else
          end;
        end;

IF_JUMP:
        begin
          // unconditional jump to label
          labelNo := readword( theData ); // target label number

          case passId of
cPassCoffCreate:
            begin
              // unconditional jump to label
              current := newitem( IF_JUMP, theType );
              setItemField( current, cItemInfo, labelNo ); // target label number
              incrementItemSize( current, 5 ); // assume long to begin with
              cad := cad + getItemField( current, cItemSize );
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();

              ptr := findlabel(labelNo);

              if (getItemField(current,cItemSize) = 2) then // short jump
              begin
                writebyte( cCODESECTION, $EB );
                writebyte( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 2 ) );

                cad := cad + 2;
              end
              else
              begin
                writebyte( cCODESECTION, $E9 ); // JMP
                writew32( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 5 ) );

                cad := cad + 5;
              end;
            end;
cPassAssemble:
            begin
              write(fout,'IF_JUMP,');
              write(fout, labelNo );
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_JUMP, theSize, theData );
            end;
          else
          end;
        end;

IF_JCOND:
        begin
          // cond jump to label JE, JNE, JLE, JL, JGE, JG
          condition := readbyte( copy( theData, 1, 2) );
          labelNo := readword( copy( theData, 3, 4) ); // target label number

          case passId of
cPassCoffCreate:
            begin
              // cond jump to label JE, JNE, JLE, JL, JGE, JG etc
              current := newitem( IF_JCOND, theType );
              // condition code is buffer[0] - not needed on this first pass
              // NB Pascal string first character at string[1]
              // but we want string[3..6] == 2 bytes == 1 word (each string char is a nibble)
              setItemField( current, cItemInfo, labelNo ); // target label number
              incrementItemSize( current, 6 ); // assume long to begin with
              cad := cad + getItemField( current, cItemSize );
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();

              ptr := findlabel(labelNo);

              if (getItemField(current,cItemSize) = 2) then // short jump
              begin
                writebyte( cCODESECTION, jcondop[condition] );
                writebyte( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 2 ) );

                cad := cad + 2;
              end
              else
              begin
                writebyte( cCODESECTION, $0F ); // prefix
                writebyte( cCODESECTION, jcondop[condition] + $10 );
                writew32( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 6 ) );

                cad := cad + 6;
              end;
            end;
cPassAssemble:
            begin
              write(fout,'IF_JCOND,');
              case condition of
            0:  write(fout,'JE');
            1:  write(fout,'JNE');
            2:  write(fout,'JG');
            3:  write(fout,'JGE');
            4:  write(fout,'JL');
            5:  write(fout,'JLE');
            6:  write(fout,'JA');
            7:  write(fout,'JAE');
            8:  write(fout,'JB');
            9:  write(fout,'JBE');
              else
                write(fout,'???');
              end;
              write(fout,',');
              write(fout,labelno );
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_JCOND, theSize, theData );
            end;
          else
          end;
        end;

IF_CALL:
        begin
          // call a label
          labelNo := readword( copy( theData, 1, 4 ) ); // target label number

          case passId of
cPassCoffCreate:
            begin
              current := newitem( IF_CALL, theType );
              setItemField( current, cItemInfo, labelNo ); // target label number
              incrementItemSize( current, 5 ); // assume long to begin with
              cad := cad + 5;
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();

              ptr := findlabel(labelNo);

              writebyte( cCODESECTION, $E8 ); // CALL
              writew32( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 5 ) );

              cad := cad + 5;
            end;
cPassAssemble:
            begin
              write(fout,'IF_CALL,');
              write(fout,labelNo);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_CALL, theSize, theData );
            end;
          else
          end;
        end;

IF_LABEL:
        begin
          // define a label
          labelNo := readword( copy( theData, 1, 4) );

          case passId of
cPassCoffCreate:
            begin
              current := newitem( IF_LABEL, theType ); // labels occupy no space
              setItemField( current, cItemInfo, labelNo ); // label number
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();
            end;
cPassAssemble:
            begin
              write(fout,'IF_LABEL,');
              write(fout,labelNo );
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_LABEL, theSize, theData );
            end;
          else
          end;
        end;

IF_FIXUP:
        begin
          // define location for stack fixup instruction
          fixupId := readword( copy( theData, 1,4 ) ); // id number for fixup
          level := readbyte( copy(theData,5,2 ) );
          name := readAscii( copy( theData, 7, length(theData) - 6) );

          case passId of
cPassCoffCreate:
            begin
              nameId := newName( name ); // debug name
              setNameUsed( nameId );
              // this routine might be global so check if external name present
              externalNameId := findNameIndexByString( '_'+name );
              if (externalNameId <> -1) then
              begin
                // This IF_FIXUP refers to an externally visible symbol
                setNameUsed( externalNameId );
              end;
              // define location for stack fixup instruction
              current := newitem( IF_FIXUP, theType );
              setItemField( current, cItemLineNo, lineno ); // debug to indicate source line in IBJ  file
              setItemField( current, cItemInfo, 0 ); // amount to subtract from the stack will be filled later
              incrementItemSize( current, 4 ); // space will be an ENTER instruction (C8, nnnn, ll)
              cad := cad + 4;

              // assume no events trapped, no label
              ptr := newstackfix();
              setStackFixField( ptr, cStackFixId, fixupid );
              setStackFixField( ptr, cStackFixHint, current );
              setStackFixField( ptr, cStackFixEvents, 0 );
              setStackFixField( ptr, cStackFixTrap, 0 );
              setStackFixField( ptr, cStackFixNameId, nameId );

              setStackFixField( ptr, cStackFixLineNo, lineno );
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();

              value := getItemField(current,cItemInfo);

              // For backward compatibility reasons (mostly because it kept messing
              // me up in development) we will plant suitable code whether this is
              // a "classic" 8086 fixup request - i.e. plant SUB SP,nnnn - or a new
              // style 80286 fixup request to plant ENTER nnnn,level.  We can tell
              // them apart because the classic passes only two parameter bytes.
              if (theSize = 4) then
              begin
                writebyte( cCODESECTION, $81 );  // SUB
                writebyte( cCODESECTION, $EC );  // SP
                writew16( cCODESECTION, value ); // Stack displacement
              end
              else
              begin
                writebyte( cCODESECTION, $C8 );   // ENTER
                writew16( cCODESECTION, value );  // Stack displacement
                writebyte( cCODESECTION, level ); // level
              end;

              // We now update our procedure record with the actual block start location
              ptr := findStackFixById( fixupId );
              setStackFixField( ptr, cStackFixStart, cad );

              cad := cad + 4;
            end;
cPassAssemble:
            begin
              write(fout,'IF_FIXUP,');
              write(fout,fixupid,',');
              write(fout, level,',');
              write(fout,'"',name,'"');
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_FIXUP, theSize, theData );
            end;
          else
          end;
        end;

IF_SETFIX:
        begin
          // stack fixup <location> <amount> <eventmask> <event entry>
          fixupId := readword( copy( theData, 1,4 ) );	              // id number for fixup
          // compiler passes value as a 16 bit negative number but we make it positive
          value   :=  (- readword( copy( theData, 5,4 ) )) and $ffff; // positive! amount to subtract
          events  := readword( copy( theData, 9,4 ) );                // on events
          trap    := readword( copy( theData, 13,4 ) );               // trap
          evfrom  := readword( copy( theData, 17,4 ) );               // on events

          case passId of
cPassCoffCreate:
            begin
              // compiler passes value as a 16 bit negative number, but we're going
              // to plant an ENTER instruction, so we make it positive...
              ptr := findStackFixById( fixupId );
              if (ptr <> -1) then
              begin
                itemPtr := getStackFixField( ptr, cStackFixHint );
                if (getItemField( itemPtr, cItemIBJType ) <> IF_FIXUP) then
                begin
                  if debug then
                  begin
                    writeln( fdebug,'**** ERROR **** Mismatch at line ',lineno,' IF_SETFIX record does NOT point to IF_FIXUP record' );
                    writeln( fdebug,'cStackFixHint field refers to a ',ibjName( getItemField( itemPtr, cItemIBJType ) ) );
                  end;
                  writeln(        '**** ERROR **** Mismatch at line ',lineno,' IF_SETFIX record does NOT point to IF_FIXUP record' );
                  writeln(        'cStackFixHint field refers to a ',ibjName( getItemField( itemPtr, cItemIBJType ) ) );
                end;

                setItemField( itemPtr, cItemInfo, value );

                // now fill in the event stuff...
                setStackFixField( ptr, cStackFixEvents, events );
                setStackFixField( ptr, cStackFixTrap, trap );
                setStackFixField( ptr, cStackFixEvFrom, evfrom );
              end
              else
              begin
                if debug then
                begin
                  writeln(fdebug,'Stack fixup for undefined ID?');
                end;
                writeln(       'Stack fixup for undefined ID?');
              end;
            end;
cPassCoffWrite:
            begin
              ptr := findStackFixById( fixupId );
              // We don't need to do anything in the code stream here, but we use
              // this record to trigger an update of the end point in our block table
              setStackFixField( ptr, cStackFixEndFn, cad );
            end;
cPassAssemble:
            begin
              write(fout,'IF_SETFIX,');
              write(fout,fixupId,',');
              write(fout,-value,',');
              write(fout,events,',');
              write(fout,trap,',');
              write(fout,evfrom);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_SETFIX, theSize, theData );
            end;
          else
          end;
        end;

IF_REQEXT:
        begin
          // external name spec
          name := readAscii( theData );

          case passId of
cPassCoffCreate:
            begin
              // clear it and count it...
              nameId := newName( name );
              if (nameId = -1) then errorFlag := true;

              specId := newSpec( nameId ); // assume this is an external code name
              if (specId = -1) then errorFlag := true;

              current := newItem( IF_REQEXT, theType ); // definitions/specs occupy no space
              setItemField( current, cItemInfo,nameId );
            end;
cPassCoffWrite:
            begin
              // already taken care of, but need to advance "current"
              current := current + 1;
              checkExpectedType();
            end;
cPassAssemble:
            begin
              nameId := newName( name );
              if (nameId = -1) then errorFlag := true;

              specId := newSpec( nameId ); // assume this is an external code name
              if (specId = -1) then errorFlag := true;

              write(fout,'IF_REQEXT');
              write(fout,',');
              write(fout,specId);
              write(fout,',');
              write(fout,'"');
              write(fout,name);
              write(fout,'"');
              writeln(fout);
            end;
cPassCompactRead:
            begin
              nameId := newName( name ); // assume this is an external code name
              if (nameId = -1) then errorFlag := true;
            end;
cPassCompactWrite:
            begin
              if getNameUsed( findNameIndexByString( name ) ) then
              begin
                writeirecord( fout, IF_REQEXT, theSize, theData );
              end;
            end;
          else
          end;
        end;

IF_REFLABEL:
        begin
          // call a label
          labelNo := readword( copy( theData, 1, 4 ) ); // target label number
          offset  := readword( copy( theData, 5, 4 ) ); // target label offset
          if (offset > 32767) then offset := -65535 + offset; 

          case passId of
cPassCoffCreate:
            begin
              current := newitem( IF_REFLABEL, theType );
              setItemField( current, cItemInfo, labelNo ); // target label number
              incrementItemSize( current, 4 ); // assume long to begin with
              cad := cad + 4;
            end;
cPassCoffWrite:
            begin
              current := current + 1;
              checkExpectedType();

              ptr := findlabel(labelNo);

              // get the relative offset to the label address
              writew32( cCODESECTION, getLabelAddress(ptr) - (getItemField(current,cItemAddress) + 4 + offset ) );
//              writew32( cCODESECTION, getLabelAddress(ptr) );

              cad := cad + 4;
            end;
cPassAssemble:
            begin
              write(fout,'IF_REFLABEL,');
              write(fout,labelNo);
              write(fout,',');
              write(fout,offset);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_REFLABEL, theSize, theData );
            end;
          else
          end;
        end;

IF_REFEXT:
        begin
          // external name relative offset code word
          checkSize( WORDSIZE );
          specId := readword( copy( theData, 1, 4 ) ); // reference index
          offset := readword(copy(theData,5,8));       // relative offset

          case passId of
cPassCoffCreate:
            begin
              // update our "used" flag
              if checkvalidSpecId( specId ) then
              begin
                setSpecUsed( specId );
                setNameUsed( getSpecNameId( specId ) );
              end
              else
              begin
                errorFlag := true;
                if debug then
                begin
                  writeln(fdebug,'**** ERROR **** invalid specId detected at @line#',lineno,' bad specId=',specId );
                end;
                writeln('**** ERROR **** invalid specId detected at @line#',lineno,' bad specId=',specId );
              end;

              incrementRelocsCount();
              if (getItemField(current,cItemType) <> IF_OBJ) then current := newItem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );

              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              for i := 1 to WORDSIZE do
              begin
                writebyte( cCODESECTION, 0 );
              end;

              writew32( cCODERELSECTION, cad );  // offset in section of word to relocate
              // skip the symbol table entries for the sections and remap according to our table
              writew32( cCODERELSECTION, getFirstUserSymbol() + getSpecP3Index( specId ) ); // symbol index for this reference
              writew16( cCODERELSECTION, $14 );   // relocate by relative 32 bit address

              // HACK ALERT - our current intermediate code can't distinguish between
              // relative and absolute external relocations, so we can't do external data
              // fixups.... oops!
              cad := cad + WORDSIZE;
            end;
cPassAssemble:
            begin
              write(fout,'IF_REFEXT,');
              write(fout,'"');
              write(fout, getNameString( getSpecNameId( specId ) ) );
              write(fout,'"');
              write(fout,',');
              write(fout,offset);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              setNameUsed( specId );
            end;
cPassCompactWrite:
            begin
              // tweak record to use renumbered (compacted) specId
              writeirecord( fout, IF_REFEXT, theSize, formword( getNameId( specId ) ) + formword( offset ) );
            end;
          else
          end;
        end;

IF_BSS:
        begin
          // BSS segment offset code word
          checkSize( WORDSIZE );
          longdata[1] := readByte( copy(theData, 1, 2 ) );
          longdata[2] := readByte( copy(theData, 3, 2 ) );
          longdata[3] := readByte( copy(theData, 5, 2 ) );
          longdata[4] := readByte( copy(theData, 7, 2 ) );

          case passId of
cPassCoffCreate:
            begin
              // All of these are treated as "object code" for the first pass
              incrementRelocsCount();
              if (getItemField(current,cItemType) <> IF_OBJ) then current := newItem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );
              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              // BSS should have been converted to OBJ
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;
            end;
cPassAssemble:
            begin
              write(fout,'IF_BSS,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_BSS, theSize, theData );
            end;
          else
          end;
        end;

IF_COTWORD:
        begin
          // Constant table word
          checkSize( WORDSIZE div 2 );
          shortdata[1] := readByte( copy(theData, 1, 2 ) );
          shortdata[2] := readByte( copy(theData, 3, 2 ) );

          case passId of
cPassCoffCreate:
            begin

              if (getItemField(current,cItemType) <> IF_COTWORD) then current := newItem( IF_COTWORD, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, 2 ); // NOTE - these are actually halfwords (so 2 bytes)
            end;
cPassCoffWrite:
            begin
              // Constant table word
              if (getItemField(current,cItemType) <> IF_COTWORD) then current := current + 1;
              checkExpectedType();

              writebyte( cCONSTSECTION, shortdata[1] );
              writebyte( cCONSTSECTION, shortdata[2] );
            end;
cPassAssemble:
            begin
              write(fout,'IF_COTWORD,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_COTWORD, theSize, theData );
            end;
          else
          end;
        end;

IF_DATWORD:
        begin
          // Data segment word
          checkSize( WORDSIZE div 2 );
          shortdata[1] := readByte( copy(theData, 1, 2 ) );
          shortdata[2] := readByte( copy(theData, 3, 2 ) );

          case passId of
cPassCoffCreate:
            begin
              if (getItemField(current,cItemType) <> IF_DATWORD) then current := newItem( IF_DATWORD, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, 2 ); // NOTE - these are actually halfwords (so 2 bytes)
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_DATWORD) then current := current + 1;
              checkExpectedType();

              writebyte( cDATASECTION, shortdata[1] );
              writebyte( cDATASECTION, shortdata[2] );
            end;
cPassAssemble:
            begin
              write(fout,'IF_DATWORD,');
              write(fout,theData);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_DATWORD, theSize, theData );
            end;
          else
          end;
        end;

IF_SWTWORD:
        begin
          // switch table entry - actually a label ID
          checkSize( WORDSIZE div 2 );
          labelNo := readword( theData ); // target label number

          case passId of
cPassCoffCreate:
            begin
              if (getItemField(current,cItemType) <> IF_SWTWORD) then current := newItem( IF_SWTWORD, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, 2 ); // NOTE - these are actually halfwords (so 2 bytes)
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_SWTWORD) then current := current + 1;
              checkExpectedType();

              ptr := findlabel( labelNo );

              writew32( cSWTABSECTION, getLabelAddress(ptr) );

              // we must also plant a relocation record to make this a code address
              writew32( cSWTABRELSECTION, swtp );            // offset in section of word to relocate
              writew32( cSWTABRELSECTION, getSymbol( cCODESECTION ) ); // symbol for section
              writew16( cSWTABRELSECTION, 6 );               // relocate by actual 32 bit address

              swtp := swtp + 4;
            end;
cPassAssemble:
            begin
              write(fout,'IF_SWTWORD,');
              write(fout,labelNo);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_SWTWORD, theSize, theData );
            end;
          else
          end;
        end;

IF_SOURCE:
        begin
          // name of the source file (generated by Imp Compiler PASS2)
          name := readAscii( theData );

          case passId of
cPassCoffCreate:
            begin
              // create a dummy item
              current := newItem( IF_SOURCE, theType );
              // remember the generated source file name
              noteSourceName( name );
            end;
cPassCoffWrite:
            begin
              // HACK ALERT - we actually ignore the file name from Imp Compiler PASS2
              // because we've got a nicer library interface and we can get the REAL path
              current := current + 1;
              checkExpectedType();
            end;
cPassAssemble:
            begin
              write(fout,'IF_SOURCE,');
              write(fout,'"');
              write(fout, name );
              write(fout,'"');
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_SOURCE, theSize, theData );
            end;
          else
          end;
        end;

IF_DEFEXTCODE:
        begin
          // define a code label that is external
          name := readAscii( theData );

          case passId of
cPassCoffCreate:
            begin
              nameId := newName( name );
              // this is a slightly cheesy way of finding if this is a main program
              if (name = '__impmain') then
              begin
                setMainProg();
                setNameUsed( nameId );
              end;

              current := newitem( IF_DEFEXTCODE, theType ); // definitions/specs occupy no space
              setItemField( current, cItemInfo, nameId );
              incrementSymbolCount();
            end;
cPassCoffWrite:
            begin
              // already taken care of, but need to advance "current"
              current := current + 1;
              checkExpectedType();
            end;
cPassAssemble:
            begin
              write(fout,'IF_DEFEXTCODE,');
              write(fout,'"');
              write(fout,name);
              write(fout,'"');
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_DEFEXTCODE, theSize, theData );
            end;
          else
          end;
        end;

IF_DEFEXTDATA:
        begin
          // define a data label that is external
          name := readAscii( theData );

          case passId of
cPassCoffCreate:
            begin
              nameId := newname( name );

              current := newitem( IF_DEFEXTDATA, theType ); // definitions/specs occupy no space
              setItemField( current, cItemInfo, nameId );
              incrementSymbolCount();
            end;
cPassCoffWrite:
            begin
              // already taken care of, but need to advance "current"
              current := current + 1;
              checkExpectedType();
            end;
cPassAssemble:
            begin
              write(fout,'IF_DEFEXTDATA,');
              write(fout,'"');
              write(fout,name);
              write(fout,'"');
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_DEFEXTDATA, theSize, theData );
            end;
          else
          end;
        end;

IF_SWT:
        begin
          // SWITCH table segment offset code word
          longdata[1] := readbyte( copy( theData, 1,2 ) );
          longdata[2] := readbyte( copy( theData, 3,2 ) );
          longdata[3] := readbyte( copy( theData, 5,2 ) );
          longdata[4] := readbyte( copy( theData, 7,2 ) );

          case passId of
cPassCoffCreate:
            begin
              checkSize( WORDSIZE );
              // All of these are treated as "object code" for the first pass
              incrementRelocsCount();
              if (getItemField(current,cItemType) <> IF_OBJ) then current := newItem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );

              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              writebyte( cCODESECTION, longdata[1] );
              writebyte( cCODESECTION, longdata[2] );
              writebyte( cCODESECTION, longdata[3] );
              writebyte( cCODESECTION, longdata[4] );

              writew32( cCODERELSECTION, cad );                        // offset in section of word to relocate
              writew32( cCODERELSECTION, getSymbol( cSWTABSECTION ) ); // symbol for section
              writew16( cCODERELSECTION, 6 );                          // relocate by actual 32 bit address

              cad := cad + WORDSIZE;
            end;
cPassAssemble:
            begin
              write(fout,'IF_SWT,');
              write(fout,readword( theData ));
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              writeirecord( fout, IF_SWT, theSize, theData );
            end;
          else
          end;
        end;

IF_LINE:
        begin
          // line number info for the debugger
          sourcelineNo := readword(copy(theData,1,4)); // get the source line number

          case passId of
cPassCoffCreate:
            begin
              // note we will recalculate this information on the second pass when
              // jump optimisation will have changed the code addresses, but in the
              // meantime we need to know how many records we will have for the line
              // number section of the object file.
              newlineno( sourcelineNo, cad );
            end;
cPassCoffWrite:
            begin
              newlineno( sourcelineNo, cad );
            end;
cPassAssemble:
            begin
              write(fout,'IF_LINE,');
              write(fout,sourcelineNo);
              writeln(fout);
            end;
cPassCompactRead:
            begin
              // do nothing
            end;
cPassCompactWrite:
            begin
              // LINE found but just remember last sourcelineno value
              // the writing of the last LINE record in a sequence
              // is handled above the case statement selectingthe IBJ record type
              lineFlag := true;
              lineData := sourcelineno;
            end;
          else
          end;
        end;

IF_ABSEXT:
        begin
          // external name relative offset code word
          // external name absolute offset code word (data external)
          checkSize( WORDSIZE );
          // The IMP77 compiler PASS2 program currently generates an ABSEXT record
          // where the actual offset is added to the specId
          offsetPlusId := readword( copy( theData, 1, 4 ) );
          specId := readword( copy( theData, 5, 4 ) ) ;
          offset := offsetPlusId - specId;

          case passId of
cPassCoffCreate:
            begin
              // update our "used" flag
              if checkvalidSpecId( specId ) then
              begin
                setSpecUsed( specId );
                setSpecIsData( specId ); // Hack to say this is a data label
              end
              else
              begin
                errorFlag := true;
                if debug then
                begin
                  writeln(fdebug,'**** ERROR **** invalid specId detected at @line#',lineno,' bad specId=',specId );
                end;
                writeln('**** ERROR **** invalid specId detected at @line#',lineno,' bad specId=',specId );
              end;
              incrementRelocsCount();

              if (getItemField(current,cItemType) <> IF_OBJ) then current := newItem( IF_OBJ, theType );
              // we don't bother to remember the code, just how big it is..
              incrementItemSize( current, WORDSIZE );

              cad := cad + WORDSIZE;
            end;
cPassCoffWrite:
            begin
              if (getItemField(current,cItemType) <> IF_OBJ) then current := current + 1;

              // Now determine the offset (currently ibj record has it as a 16 bit value == 4 nibbles)
              // the offset is in buffer[0,1] - it should always be a positive number
              // However the Imp Compiler Pass2  doesn't generate a valid IF_ABSEXT record
              // Due to current implementation of Imp Compiler Pass2 -
              // the offset in buffer[0,1] also includes the base index of the underlying symbol
              writew32( cCODESECTION, offset );

              writew32( cCODERELSECTION, cad );                                     // offset in section of word to relocate
              // id == reference index is in buffer[2,3], which we should already have
              // skip the sections symbol table entries and remap according to our table
              writew32( cCODERELSECTION, getFirstUserSymbol() + getSpecP3Index(specid) ); // symbol index for this reference
//              writew16( CODERELSECTION, 0x14 );                                    // relocate by relative 32 bit address
              writew16( cCODERELSECTION, 6 );                                       // relocate by actual 32 bit address

              // HACK ALERT - our current intermediate code can't distinguish between
              // relative and absolute external relocations, so we can't do external data
              // fixups.... oops!
              cad := cad + WORDSIZE;
            end;
cPassAssemble:
            begin
              write(fout,'IF_ABSEXT,');
              write(fout,'"');
              write(fout, getNameString( getSpecNameId( specId ) ) );
              write(fout,'"');
              write(fout,',');
              write(fout, offset );
              writeln(fout);
            end;
cPassCompactRead:
            begin
              setNameUsed( specId );
            end;
cPassCompactWrite:
            begin
              (* symbol id given by theData[5..8] *)
              (* offset from symbol given by evaluating theData[1,4] - theData[5..8] *)
              newSpecId := getNameId( specId );
              newoffsetPlusId := newSpecId + offset;

              writeirecord( fout, IF_ABSEXT, theSize, formword( newoffsetPlusId ) + formword( newSpecId ) );
            end;
          else
          end;
        end;
      else
        if debug then
        begin
          writeln(fdebug,'**** ERROR **** @',lineno,': UNKNOWN TYPE ',theType,' found with data ',theData);
        end;
        writeln(       '**** ERROR **** @',lineno,': UNKNOWN TYPE ',theType,' found with data ',theData);
        errorFlag := true;
      end;
    end;

    if debug then
    begin
      close(fdebug);
    end;

    case passId of
cPassCoffCreate:
      begin
        close(fin);
      end;
cPassCoffWrite:
      begin
        close(fin);
      end;
cPassAssemble:
      begin
        close(fin);
        close(fout);
      end;
cPassCompactRead:
      begin
        close(fin);
      end;
cPassCompactWrite:
      begin
        close(fin);
        close(fout);
      end;
    else
    end;

    parseIBJFile := not errorFlag;
  end;

end.
