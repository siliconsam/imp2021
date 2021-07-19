{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program assemble2ibj(input,output);
uses
  dos,
  sysutils,
  ibjutil,
  nameutil,
  specutil;

const
  version = '1.2';

  procedure initialise;
  begin
    initialiseNames();
    initialiseSpecs();
  end;

  function assembleIBJFile( infilename, outfilename : string ): boolean;
  const
    cMaxParam = 7;
  var
    fin,
    fout : text;
    lineNo : integer;
    ibjline : string;

    i1 : integer;
    i2 : integer;
    i3 : integer;
    i4 : integer;
    i5 : integer;
    offset : integer;
    name : string;

    pass1error : boolean;

    params : array [0..cMaxParam] of string;
    paramcount : integer;
  begin
    assign( fin, infilename );
    reset( fin );
    lineno := 0;

    assign( fout, outfilename );
    rewrite( fout );

    pass1error := false;

    (* Now to read the IBJ file until the end of file *)
    while not eof(fin) do
    begin
      (* read the current line and update the count of lines read so far *)
      readln( fin, ibjline );
      lineNo := lineNo + 1;

      (* split the input line based on , as seperator *)
      (* Hopefully there will be less than 7 commas *)
      paramcount := 0;
      params[paramcount] := ibjline;
      while (pos(',',params[paramcount]) > 0) and (paramcount < cMaxParam) do
      begin
        i1 := pos(',',params[paramcount]);
        i2 := length(params[paramcount]);
        params[paramcount+1] := copy(params[paramcount],i1+1,i2 - i1);
        params[paramcount] := copy(params[paramcount],1,i1-1);
        paramcount := paramcount + 1;
      end;

      case IBJCode( params[0] ) of
IF_OBJ:
        begin
          writeirecord( fout, IF_OBJ, length(params[1]) shr 1, params[1] );
        end;

IF_DATA:
        begin
          writeirecord( fout, IF_DATA, length(params[1]) shr 1, params[1] );
        end;

IF_CONST:
        begin
          writeirecord( fout, IF_CONST, length(params[1]) shr 1, params[1] );
        end;

IF_DISPLAY:
        begin
          writeirecord( fout, IF_DISPLAY, length(params[1]) shr 1, params[1] );
        end;

IF_JUMP:
        begin
          writeirecord( fout, IF_JUMP, 2 , formword( strToInt(params[1]) ) );
        end;

IF_JCOND:
        begin
          writeirecord( fout, IF_JCOND, 3 , formByte( TestCode( params[1] ) ) + formword( strToInt(params[2]) ) );
        end;

IF_CALL:
        begin
          writeirecord( fout, IF_CALL, 2 , formword( strToInt(params[1]) ) );
        end;

IF_LABEL:
        begin
          writeirecord( fout, IF_LABEL, 2 , formword( strToInt(params[1]) ) );
        end;

IF_FIXUP:
        begin
          (* remove the enclosing string quotes *)
          i1 := strToInt(params[1]);
          i2 := strToInt(params[2]);
          name := copy(params[3],2,length(params[3]) - 2);

          writeirecord( fout, IF_FIXUP, 3 + length(name) , formword( i1 ) + formbyte( i2 ) + formstring( name ) );
        end;

IF_SETFIX:
        begin
          i1 := strToInt(params[1]);
          i2 := strToInt(params[2]);
          i3 := strToInt(params[3]);
          i4 := strToInt(params[4]);
          i5 := strToInt(params[5]);

          writeirecord( fout, IF_SETFIX, 10 , formword( i1 )+ formword( i2 ) + formword( i3 ) + formword( i4 ) + formword( i5 ) );
        end;

IF_REQEXT:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[2],2,length(params[2]) - 2);

          if (newName( name ) = -1) then pass1error := true;
          if (newSpec( findNameIndexByString( name ) ) = -1) then pass1error := true;

          writeirecord( fout, IF_REQEXT, length( name ) shr 1 , formstring( name ) );
        end;

IF_REFLABEL:
        begin
          i1 := strToInt(params[1]);
          i2 := strToInt(params[2]);

          writeirecord( fout, IF_REFLABEL, 4 , formword(i1) + formword(i2) );
        end;

IF_REFEXT:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[1],2,length(params[1]) - 2);

          (* from the name, get the nameId, then search for the specId *)
          i1 := findNameIndexByString( name );
          offset := strToInt(params[2]);

          writeirecord( fout, IF_REFEXT, 4, formword(i1) + formword(offset) );
        end;

IF_BSS:
        begin
          writeirecord( fout, IF_BSS, length(params[1]) shr 1, params[1] );
        end;

IF_COTWORD:
        begin
          writeirecord( fout, IF_COTWORD, length(params[1]) shr 1, params[1] );
        end;

IF_DATWORD:
        begin
          writeirecord( fout, IF_DATWORD, length(params[1]) shr 1, params[1] );
        end;

IF_SWTWORD:
        begin
          writeirecord( fout, IF_SWTWORD, 2, formword( strToInt( params[1] )  ) );
        end;

IF_SOURCE:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[1],2,length(params[1]) - 2);

          writeirecord( fout, IF_SOURCE, length( name ), formstring( name ) );
        end;

IF_DEFEXTCODE:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[1],2,length(params[1]) - 2);

          writeirecord( fout, IF_DEFEXTCODE, length( name ), formstring( name ) );
        end;

IF_DEFEXTDATA:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[1],2,length(params[1]) - 2);

          writeirecord( fout, IF_DEFEXTDATA, length( name ), formstring( name ) );
        end;

IF_SWT:
        begin
          i1 := strToInt(params[1]);

          writeirecord( fout, IF_SWT, 4, formword( i1 ) + formword( i1 shr 16 ) );
        end;

IF_LINE:
        begin
          i1 := strToInt(params[1]);

          writeirecord( fout, IF_LINE, 2, formbyte( i1 ) + formbyte( i1 shr 8 ) );
        end;

IF_ABSEXT:
        begin
          (* remove the enclosing string quotes *)
          name := copy(params[1],2,length(params[1]) - 2);

          i1 := findSpecIndexByNameId( findNameIndexByString( name ) );
          i2 := i1 + strToInt( params[2] );

          writeirecord( fout, IF_ABSEXT, 4, formword( i2 ) + formword( i1 ) );
        end;

      else
        writeln('**** ERROR **** Unexpected IBJ command ',params[0],' at line ',lineno);
      end;

    end;
    close(fin);
    close(fout);
    
    assembleIBJFile := not pass1error;
  end;

  procedure help();
  begin
    writeln('assemble2ibj: Version ',version);
    writeln('assemble2ibj: 2 parameters expected: assemble2ibj [ibj assemble file] [ibj file]');
  end;

begin
  if (ParamCount = 2) then
  begin
    if fileExists( ParamStr( 1) ) then
    begin
      initialise();
      if not assembleIBJFile( ParamStr(1), ParamStr(2) ) then
      begin
        writeln( ' **** ERROR **** Input assembler File ',ParamStr(1),' has errors' );
      end;
    end
    else
    begin
      writeln( ' **** ERROR **** Input File ',ParamStr(1),' does not exist!' );
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
