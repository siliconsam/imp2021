{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program assemble2icd(input,output);
uses
  dos,
  strutils,
  sysutils,
  icoderec,
  icdio,
  symTable;

var
  fin : text;
  fout : text;
  ficd : ficode;
  debugFlag : boolean;

  inStart,defMode : boolean;

  function toLongIntString( n : longint ): string;
  type
    x =
    packed record
      case boolean of
false:  ( s : array[1..4] of char; );
 true:  ( n : longint; );
    end;
  var
    xx : x;
  begin
    xx.n := n;

    toLongIntString := xx.s[4] + xx.s[3] + xx.s[2] + xx.s[1];
  end;

  function toShortIntString( n : longint ): string;
  type
    x =
    packed record
      case boolean of
false:  ( s : array[1..4] of char; );
 true:  ( n : integer; );
    end;
  var
    xx : x;
  begin
    xx.n := n;

    toShortIntString := xx.s[2] + xx.s[1];
  end;

  procedure assemble();
  var
    iCodeLine : string;
    sourceLine : string;
    lineNo : integer32;
    
    Params : tStringArray;
    SplitParam : tStringArray;

    s,t,
    s1,
    s2 : string;

    altMode : char;
    int1 : integer32;
    uint1,
    uint2 : uinteger32;
    str1 : string;
    passId,
    passValue : integer32;
    d : double;
    i,j,base : integer;
    
    r : tIcodeRec;
  begin
    // Clear the lineno count
    lineno := 0;
    (* Now to read the ICODE assembly text file until the end of file *)
    while not eof(fin) do
    begin
      repeat
        (* read the current iCode line *)
        readln( fin, iCodeLine );

        sourceLine := iCodeLine;
        (* remove any leading spaces *)
        while (sourceLine[1] = ' ') do sourceLine := copy( sourceline, 2, length( sourceLine ) - 1 );
        (* remove any trailing spaces *)
        while (sourceLine[ length( sourceLine ) ] = ' ') do sourceLine := copy( sourceLine, 1, length( sourceLine ) - 1 );
        (* update the count of lines read so far *)
        lineNo := lineNo + 1;

        // If this is a comment line then output the original text
        if (sourceLine[1] = '!') then writeln( fout, iCodeLine );
      until (sourceLine[1] <> '!') or eof(fin);

      (* Now split the line using space characters as a seperator *)
      Params := SplitString( sourceLine, ' ' );

      (* parse the 0'th parameter to an iCode byte and take appropriate action *)
      r := newRecByMnemonic( params[0] );

      if (r.icode = chr(255)) then
      begin
        (* UNUSED *)
        writeln(     '**** <',params[0],'> ILLEGAL/UNKNOWN/UNUSED ICODE MNEMONIC @',lineNo,' ****,');
        writeln(fout,'**** <',params[0],'> ILLEGAL/UNKNOWN/UNUSED ICODE MNEMONIC @',lineNo,' ****,');
      end
      else if not eof(fin) then
      begin
        case r.icode of
chr(10):
          begin
            (* NL masquerading as EOF? *)
            (* Ignore anyway *)
          end;
'!':      begin
            (* OR *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'"':      begin
            (* JUMPIFD *)
            (* COMPARE DOUBLE *)
            str1 := params[1];
            uint1 := StrToInt( copy( params[2], 2, length( params[2] ) - 1 ) );

            writeinst( ficd, r.icode );
            writechar( ficd, fromTest( str1 ) );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic, ' ',str1,' $',uint1 );
            end;
          end;
'#':      begin
            (* JNE *)
            (* JUMP FORWARD *)
            uint1 := StrToInt( copy( params[1], 2, length(params[1]) - 1) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic, ' $',uint1 );
            end;
          end;
'$':      begin
            (* DEF *)
            { add the name to the name stack }
            r.name := copy( params[1], 2, length( params[1] ) - 2 );
            { Needed at this point so a record format type defn can refer to itself }
            r.tag := pushSymbol( r.name );

            r.defTypeForm := $0000;
            case params[5] of
         'VOID': r.defTypeForm := $0000;
       'SIMPLE': r.defTypeForm := $0001;
         'NAME': r.defTypeForm := $0002;
        'LABEL': r.defTypeForm := $0003;
 'RECORDFORMAT': r.defTypeForm := $0004;
        'FORM5': r.defTypeForm := $0005;
       'SWITCH': r.defTypeForm := $0006;
      'ROUTINE': r.defTypeForm := $0007;
     'FUNCTION': r.defTypeForm := $0008;
          'MAP': r.defTypeForm := $0009;
    'PREDICATE': r.defTypeForm := $000A;
        'ARRAY': r.defTypeForm := $000B;
    'ARRAYNAME': r.defTypeForm := $000C;
    'NAMEARRAY': r.defTypeForm := $000D;
'NAMEARRAYNAME': r.defTypeForm := $000E;
            else
            end;

            r.defSize := 0;
            case params[4] of
         'VOID': begin r.defTypeForm := r.defTypeForm or $0000; r.defSize := $0000; end;
      'INTEGER': begin r.defTypeForm := r.defTypeForm or $0010; r.defSize := $0001; end;
         'BYTE': begin r.defTypeForm := r.defTypeForm or $0010; r.defSize := $0002; end;
        'SHORT': begin r.defTypeForm := r.defTypeForm or $0010; r.defSize := $0003; end;
         'LONG': begin r.defTypeForm := r.defTypeForm or $0010; r.defSize := $0004; end;
         'QUAD': begin r.defTypeForm := r.defTypeForm or $0010; r.defSize := $0005; end;
         'REAL': begin r.defTypeForm := r.defTypeForm or $0020; r.defSize := $0001; end;
       'DOUBLE': begin r.defTypeForm := r.defTypeForm or $0020; r.defSize := $0004; end;
    'STRING(*)': begin r.defTypeForm := r.defTypeForm or $0030; r.defSize := $0000; end;
    'RECORD(*)': begin r.defTypeForm := r.defTypeForm or $0040; r.defSize := $0000; end;
      'BOOLEAN': begin r.defTypeForm := r.defTypeForm or $0050; r.defSize := $0000; end;
          'SET': begin r.defTypeForm := r.defTypeForm or $0060; r.defSize := $0000; end;
      'POINTER': begin r.defTypeForm := r.defTypeForm or $0090; r.defSize := $0000; end;
         'CHAR': begin r.defTypeForm := r.defTypeForm or $00A0; r.defSize := $0000; end;
            else
            end;

            if (pos('STRING(',params[4]) <> 0) then
            begin
              if (params[4] <> 'STRING(*)') then
              begin
                r.defTypeForm := r.defTypeForm or $0030;
                r.defSize := StrToInt( copy( params[4], 8, length( params[4] ) - 8 ) );
              end;
            end;

            if (pos('RECORD(',params[4]) <> 0) then
            begin
              if (params[4] <> 'RECORD(*)') then
              begin
                r.defTypeForm := r.defTypeForm or $0040;
                r.defSize := lookupsymbol( copy( params[4], 9, length( params[4] ) - 10 ) );
                if (r.defSize = r.tag) then
                begin
                  r.defTypeForm := $0044; // record format type definition!
                end;
              end;
            end;

            if (pos('ENUM8(',params[4]) <> 0) then
            begin
              r.defTypeForm := r.defTypeForm or $0070;
              r.defSize := lookupsymbol( copy( params[4], 8, length( params[4] ) - 9 ) );
            end;

            if (pos('ENUM16(',params[4]) <> 0) then
            begin
              r.defTypeForm := r.defTypeForm or $0080;
              r.defSize := lookupsymbol( copy( params[4], 9, length( params[4] ) - 10 ) );
            end;

            // parse the flags and xtype
            r.defDim   := $00;
            case params[3] of
     'AUTO':  r.defFlags := $00;
      'OWN':  r.defFlags := $01;
 'CONSTANT':  r.defFlags := $02;
 'EXTERNAL':  r.defFlags := $03;
   'SYSTEM':  r.defFlags := $04;
  'DYNAMIC':  r.defFlags := $05;
'PRIMITIVE':  r.defFlags := $06;
'PERMANENT':  r.defFlags := $07;
            else
              r.defFlags := $00;
            end;
            if (pos( 'B7FLAG',   params[6] ) <> 0 ) then r.defFlags := r.defFlags or $80;
            if (pos( 'B6FLAG',   params[6] ) <> 0 ) then r.defFlags := r.defFlags or $40;
            if (pos( 'CHECK',    params[6] ) <> 0 ) then r.defFlags := r.defFlags or $20;
            if (pos( 'INDIRECT', params[6] ) <> 0 ) then r.defFlags := r.defFlags or $10;
            if (pos( 'SPEC',     params[6] ) <> 0 ) then r.defFlags := r.defFlags or $08;

            // Ok, the various icd values
            r.defMode := false;

            r.assembly := formAssembly( r );

            writeinst( ficd, r.icode );
            writetag(ficd,r.tag);
            writeascii(ficd,r.name);
            writetag(ficd,r.defTypeForm);
            writecomma(ficd);
            writetag(ficd,r.defSize);
            writecomma(ficd);
            writeuinteger8(ficd,r.defDim);
            writeuinteger8(ficd,r.defFlags);

            if debugFlag then
            begin
//              tablevels( fout );
//              writeln( fout,'! tag=',r.tag );

              tablevels( fout );
              writeln( fout, r.mnemonic,' ',r.assembly );
            end;

            { determine various assembler mode variables }
            if (not inStart) then
            begin
              if r.defMode then defMode := true;
            end;

          end;
'%':      begin
            (* XOR *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'&':      begin
            (* AND *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'''':     begin
            (* PUSHS *)
            if (length( params ) > 2) then
            begin
              str1 := params[1];
              for i := 3 to length( params ) do
              begin
                str1 := str1 + ' ' + params[i-1];
              end;
            end
            else
            begin
              str1 := params[1];
            end;

            str1 := copy( str1, 2, length( str1 ) - 2);

            writeinst( ficd, r.icode );
            writestring( ficd, str1 );

            if debugFlag then
            begin
              tablevels( fout );
              if AnsiContainsStr( str1, '"' ) then
              begin
                write( fout, r.mnemonic,' ''',str1,'''' );
              end
              else
              begin
                write( fout, r.mnemonic,' "',str1,'"' );
              end;
              writeln( fout );
            end;
          end;
'(':      begin
            (* JLE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
')':      begin
            (* JGE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'*':      begin
            (* MUL *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'+':      begin
            (* ADD *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'-':      begin
            (* SUB *)
           writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'.':      begin
            (* CONCAT *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'/':      begin
            (* QUOT *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
':':      begin
            (* LOCATE *)
            (* Compiler generated label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1);
            end;
          end;
';':      begin
            (* END *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              finishlevels( fout );
              writeln( fout, r.mnemonic );
            end;

            popFrame();

          end;
'<':      begin
            (* JL *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'=':      begin
            (* JE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'>':      begin
            (* JG *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'?':      begin
            (* JUMPIF *)
            (* COMPARE VALUES *)
            (* JUMP FORWARD to Compiler label *)
            str1 := fromTest( params[1] );
            uint1 := StrToInt( copy( params[2], 2, length( params[2] ) - 1 ) );

            writeinst( ficd, r.icode );
            writechar( ficd, fromTest( str1 ) );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',toTest(str1[1]),' $',uint1 );
            end;
          end;
'@':      begin
            (* PUSH *)
            str1 := copy( params[1], 2, length( params[1] ) - 2 );
            uint1 := lookupsymbol( str1 );

            writeinst( ficd, r.icode );
            writetag( ficd, lookupsymbol( str1 ) );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' "',str1,'"' );
            end;
          end;
'A':      begin
            (* INIT *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'B':      begin
            (* REPEAT *)
            (* JUMP BACKWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'C':      begin
            (* JUMPIFA *)
            (* COMPARE ADDRESSES *)
            (* JUMP FORWARD to Compiler label *)
            str1 := params[1];
            uint1 := StrToInt( copy( params[2], 2, length( params[2] ) - 1 ) );

            writeinst( ficd, r.icode );
            writechar( ficd, fromTest( str1 ) );
            writetag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',str1,' $',uint1 );
            end;
          end;
'D':      begin
            (* PUSHR *)
            SplitParam := SplitString( params[1], '@' );
            s1 := Splitparam[0];
            if (Length( SplitParam ) > 1) then
            begin
              s2 := SplitParam[1];
            end
            else
            begin
              s2 := '0';
            end;
            str1 := s1;
            int1 := StrToInt( s2 );

            d := icodeFloatToDouble( str1, int1 );
            str1 := doubleToIcodeMantissa( d );
            int1 := doubleToIcodeExponent( d );

            writeinst( ficd, r.icode );
            writefloat( ficd, str1, int1 );

            if debugFlag then
            begin
              tablevels( fout );
              if (int1 = 0) then
              begin
                write( fout, r.mnemonic,' ',str1 );
                if debugFlag then write( fout, ' aka ',iCodeFloatToDouble(str1,0));
              end
              else
              begin
                write( fout, r.mnemonic,' ',str1, '@',int1 );
                if debugFlag then write( fout, ' aka ',iCodeFloatToDouble(str1,int1));
              end;
              writeln( fout );
            end;
          end;
'E':      begin
            (* CALL *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'F':      begin
            (* GOTO *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'G':      begin
            (* ALIAS *)
            str1 := copy( params[1], 2, length( params[1] ) - 2 );

            writeinst( ficd, r.icode );
            writestring( ficd, str1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' "',str1,'"' );
            end;
          end;
'H':      begin
            (* BEGIN *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;

            pushFrame;
          end;
'J':      begin
            (* JUMP *)
            (* JUMP to User label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' L',uint1 );
            end;
          end;
'K':      begin
            (* FALSE *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'L':      begin
            (* LABEL *)
            (* User label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' L',uint1 );
            end;
          end;
'M':      begin
            (* MAP *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'N':      begin
            (* PUSHI *)
            int1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeinteger32( ficd, int1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',int1 );
            end;
          end;
'O':      begin
            (* LINE *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              { don't indent the LINE operator }
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'P':      begin
            (* PLANT *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'Q':      begin
            (* DIVIDE *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'R':      begin
            (* RETURN *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'S':      begin
            (* ASSVAL *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'T':      begin
            (* TRUE *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'U':      begin
            (* NEGATE *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'V':      begin
            (* RESULT *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'W':      begin
            (* SJUMP *)
            (* SWITCH jump *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'X':      begin
            (* IEXP *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'Y':      begin
            (* DEFAULT *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'Z':      begin
            (* ASSREF *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'[':      begin
            (* LSH *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'\':      begin
            (* NOT *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
']':      begin
            (* RSH *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'^':      begin
            (* SET-FORMAT *)
            str1 := params[1];

            writeinst( ficd, r.icode );
            writeTag( ficd, lookupsymbol(str1) );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ', str1 );
            end;
          end;
'_':      begin
            (* SLABEL *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'a':      begin
            (* ACCESS *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'b':      begin
            (* BOUNDS *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'd':      begin
            (* DIM *)
            SplitParam := SplitString( params[1], ',' );
            s1 := Splitparam[0];
            if (Length( SplitParam ) > 1) then
            begin
              s2 := SplitParam[1];
            end
            else
            begin
              s2 := '0';
            end;
            uint1 := StrToInt( s1 );
            uint2 := StrToInt( s2 );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );
            writeComma( ficd );
            writeTag( ficd, uint2 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1,',',uint2 );
            end;
          end;
'e':      begin
            (* EVENT *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'f':      begin
            (* FOR *)
            (* Compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'i':      begin
            (* INDEX *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'j':      begin
            (* JAM *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'k':      begin
            (* JZ *)
            (* JUMP FORWARD to compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'l':      begin
            (* LANG *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'm':      begin
            (* MONITOR *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'n':      begin
            (* SELECT *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
'o':      begin
            (* ON *)
            (* On event Jump to compiler label *)
            uint1 := StrToInt( params[1] );
            uint2 := StrToInt( copy( params[2], 2, length( params[2] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );
            writeComma( ficd );
            writeTag( ficd, uint2 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1,' $',uint2 );
            end;
          end;
'p':      begin
            (* ASSPAR *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'q':      begin
            (* SUBA *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'r':      begin
            (* RESOLVE *)
            uint1 := StrToInt( params[1] );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',uint1 );
            end;
          end;
's':      begin
            (* STOP *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
't':      begin
            (* JNZ *)
            (* JUMP FORWARD to compiler label *)
            uint1 := StrToInt( copy( params[1], 2, length( params[1] ) - 1 ) );

            writeinst( ficd, r.icode );
            writeTag( ficd, uint1 );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' $',uint1 );
            end;
          end;
'u':      begin
            (* ADDA *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'v':      begin
            (* MOD *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'w':      begin
            (* MCODE *)
            str1 := params[1];

            { ok, if there are extra spaces after the instruction, between the instruction parameters }
            { then re-form the parameters into a single string }
            s := params[2];
            if (length( params ) > 3) then
            begin
              for i := 3 to length( params ) - 1 do
              begin
                s := s + ' ' + params[i];
              end;
            end;

            { Now to parse the parameter string }
            while (length(s) > 0) do
            begin
              { parse the string according to the following rules                 }
              { Rm      : (a register) so skip the 'R' and deal with the number m }
              { x(x,d)* : variable : grab the variable name                       }
              {                       where x = ucase/lcase letter and d == digit }
              {                       lookup the variable and replace by the tag  }
              {                       16-bit integer - most sig bits to left      }
              { %x(x,d)* : assembler text : convert the x(x,d)* chars by adding   }
              {                             $80 to each ascii char.               }
              {                             Replsce x(x,d)* by the new string     }
              { d+ or d+_d+ : d+ = m (a number) or d+_d+ = m_n (a n to base n)    }
              {               Take care when recognising the two variants         }
              { Examine thew first char (and possibly second char) in the string  }
              { to determine which format the string head represents.             }
              case s[1] of
   'a'..'z',
   'A'..'Z':
                begin
                  if (length( s ) > 1) and (s[1] = 'R') and (s[2] in ['0'..'9']) then
                  begin
                    // Ok, I think this is a register
                    // So, ignore the 'R' prefix and let the next iteration
                    // recognise the register number
                    // so no change to str1
                    i := 2;
                  end
                  else if (length( s ) > 2) and (intelReg(s) > 0) then
                  begin
                    // Ok, I think this is an Intel 386 register
                    // We "adjust" s to contain the corresponding reg number
                    // prefixed by 'R'
                    s := 'R' + IntToStr( intelReg(s) ) + copy( s, 4, 1 + length( s ) - 4 );
                    i := 2;
                  end
                  else
                  begin
                    // Ok, I think this is an IMP77 variable
                    // We allow a variable to start with any letter
                    // but NO variable can have the form Rd(d,x)*
                    i := 1;
                    t := '';
                    while (i <= length(s)) and (s[i] in ['0'..'9','a'..'z','A'..'Z']) do
                    begin
                      t := t + s[i];
                      i := i + 1;
                    end;
                    // Ok, I think we have found the variable
                    j := lookupsymbol( t );
                    // Remember a variable tag is prefixed by a space
                    str1 := str1 + ' ' + toShortIntString( j );
                  end;
                end;
   '0'..'9':
                begin
                  // ok, we are looking at a number
                  // however, it could be a non-base ten number
                  i := 1; base := 0;
                  while (i <= length(s)) and (s[i] in ['0'..'9']) do
                  begin
                    base := base*10 + ord(s[i]) - ord('0');
                    i := i + 1;
                  end;
                  // check to see if the number just evaluated is the base indicator
                  if (i < length( s )) and (s[i] = '_') then
                  begin
                    // yes, the '_' is found
                    // so the next char sequence could be the actual number in the specified base
                    // We ONLY allow the number base to be 2..16 so we have to allow the possible
                    // hexadecimal characters 'a'..'f', 'A'..'F'
                    i := i + 1; t := '';
                    while (i <= length(s)) and (s[i] in ['0'..'9','a'..'f','A'..'F']) do
                    begin
                      t := t + s[i];
                      i := i + 1;
                    end;

                    case base of
                  2:  str1 := str1 + 'N' + toLongIntString( StrToInt( '%' + t ) );  // convert binary string
                  8:  str1 := str1 + 'N' + toLongIntString( StrToInt( '&' + t ) );  // convert octal string
                 16:  str1 := str1 + 'N' + toLongIntString( StrToInt( '$' + t ) );  // convert hexadecimal string
                    else
                      // unexpected number base
                      str1 := str1 + 'N' + toLongIntString( StrToInt( '$' + t ) ); // unknown base so default to hexadecimal
                    end;
                  end
                  else
                  begin
                    // no, we have retrieved a base ten number
                    str1 := str1 + 'N' + toLongIntString( base );
                  end;
                end;
        '%':
                begin
                  i := 2;
                  t := '';
                  while (i <= length(s)) and (s[i] in ['0'..'9','a'..'z','A'..'Z']) do
                  begin
                    t := t + chr( $80 + ord( s[i] ) );
                    i := i + 1;
                  end;
                  str1 := str1 + t;
                end;
        ' ':
                begin
                  i := 2;
                  // All spaces are ignored
                end;
              else
                // allow the remaining single ASCII chars i.e. ',', '<', '>' through
                str1 := str1 + s[1];
                i := 2;
              end;

              // i should point to the next location in s to be parsed
              if (i > length(s)) then
              begin
                // oops, string s completely parsed
                s := '';
              end
              else
              begin
                // ok, more to do
                // so prune the string s being parsed
                s := copy( s, i, 1 + length( s ) - i );
              end;

            end;

            writeinst( ficd, r.icode );
            putascii( ficd, str1, ';' );

            if debugFlag then
            begin
              // need to create str1 from the assemble text line
              // params[1] = instruction (ended by _)
              r.str1 := str1;
              r.assembly := formAssembly( r );

              tablevels( fout );

              write( fout, r.mnemonic,' ' );
              writeln( fout, r.assembly );
            end;

          end;
'x':      begin
            (* REXP *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'y':      begin
            (* DIAG *)
            SplitParam := SplitString( params[1], ',' );
            s1 := Splitparam[0];
            if (Length( SplitParam ) > 1) then
            begin
              s2 := SplitParam[1];
            end
            else
            begin
              s2 := '0';
            end;
            passId := StrToInt( s1 );
            passValue := StrToInt( s2 );

            writeinst( ficd, r.icode );
            writeTag( ficd, (passId shl 14) + PassValue );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',passId,',',passValue );
            end;
          end;
'z':      begin
            (* CONTROL *)
            SplitParam := SplitString( params[1], ',' );
            s1 := Splitparam[0];
            if (Length( SplitParam ) > 1) then
            begin
              s2 := SplitParam[1];
            end
            else
            begin
              s2 := '0';
            end;
            passId := StrToInt( s1 );
            passValue := StrToInt( s2 );

            writeinst( ficd, r.icode );
            writeTag( ficd, (passId shl 14) + PassValue );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic,' ',passId,',',passValue );
            end;
          end;
'{':      begin
            (* START *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;

            (* gtype indicates if record format/routine def/routine spec *)
            (* set by preceding DEF *)
            pushFrame;
            inStart := true;

          end;
'|':      begin
            (* ALT_PSR *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              tablevels( fout );
              writeln( fout, r.mnemonic );
            end;
          end;
'}':      begin
            (* FINISH *)
            writeinst( ficd, r.icode );

            if debugFlag then
            begin
              finishlevels( fout );
              writeln( fout, r.mnemonic );
            end;

            if not defMode then
            begin
              popframe;
            end;
            inStart := false;
            defMode := false;

          end;
'~':      begin
            (* ALT *)
            case params[1] of
    'BEGIN':  altMode := 'A';
      'END':  altMode := 'B';
     'NEXT':  altMode := 'C';
            else
              altMode := 'X';
            end;

            writeinst( ficd, r.icode );
            writechar( ficd, altMode );

            if debugFlag then
            begin
              tablevels( fout );
              case altMode of
          'A':  writeln( fout, r.mnemonic,' BEGIN');
          'B':  writeln( fout, r.mnemonic,' END');
          'C':  writeln( fout, r.mnemonic,' NEXT');
              else
              end;
            end;
          end;
        else
        end;
      end;
    end;
  end;

  procedure help();
  begin
    writeln('ASSEMBLE2ICD: 2 or 3 parameters expected:');
    writeln('First 2 parameters <icode input> <assembler output>');
    writeln('Third parameter indicates additional debug information');
    writeln('e.g. assemble2icd [icodefile] [iasmfile] -debug');
  end;

begin
  if ((ParamCount = 3) and (ParamStr(3) = '-debug')) or (ParamCount = 2) then
  begin
    if FileExists( ParamStr(1) ) then
    begin
      debugFlag := ((ParamCount = 3) and (ParamStr(3) = '-debug'));

      assign( fin, ParamStr( 1 ) );
      reset( fin );

      assign( ficd, ParamStr( 2 ) );
      rewrite( ficd );

      if debugFlag then
      begin
        assign( fout, ParamStr( 1 )+'.debug' );
        rewrite( fout );
      end;

      inStart := false;
      defMode := false;
      initSymStack;

      pushFrame;
      assemble();

      close(fin);
      write( ficd, ord(';') );
      write( ficd, 10 );
      close(ficd);

      if debugFlag then
      begin
        close(fout);
      end;
    end
    else
    begin
      writeln('Oops! Input file does not exist!');
      writeln();
      help();
    end;
  end
  else
  begin
    help();
  end;
end.