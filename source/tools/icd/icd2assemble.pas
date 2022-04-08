{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program icd2assemble(input,output);
uses
  dos,
  strutils,
  sysutils,
  icoderec,
  icdio,
  symTable;

var
  fin : ficode;
  fout : text;
  ficd : ficode;
  iByte : uinteger8;
  lineNo : integer32;
  debugFlag : boolean;

  inStart,defMode : boolean;

  procedure disassemble();
  var
    altMode : char;
    int1 : integer32;
    uint1,
    uint2 : uinteger32;
    b1,b2 : uinteger8;
    str1 : string;
    passId,
    passValue : integer32;
    d : double;
    
    r : tIcodeRec;
  begin
    (* Now to read the ICD file until the end of file *)
    while not eof(fin) do
    begin
      (* read the current iCode instruction and update the count of lines read so far *)
      read(fin, ibyte );
      r := newrecByChar( chr( ibyte ) );

      lineNo := lineNo + 1;

      if r.icode = chr(255) then
      begin
        (* UNUSED *)
        writeln(     '**** <',chr(ibyte),'> ILLEGAL/UNKNOWN/UNUSED ICODE TYPE @',lineNo,' ****,');
        writeln(fout,'**** <',chr(ibyte),'> ILLEGAL/UNKNOWN/UNUSED ICODE TYPE @',lineNo,' ****,');
      end
      else
      begin
        case r.iCode of
chr(10):
          begin
            (* NL masquerading as EOF? *)
            (* Ignore anyway *)
          end;
'!':      begin
            (* OR *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'"':      begin
//            (* JUMPIFD *)
            (* COMPARE DOUBLE *)
//            r.test := readchar(fin);
//            r.clabel := readtag(fin);

            tablevels( fout );
//            writeln( fout, r.mnemonic,' ',toTest(r.test),' $',r.clabel );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
//              writechar( ficd, r.test );
//              writetag( ficd, r.clabel );
            end;
          end;
'#':      begin
            (* JNE *)
            (* JUMP FORWARD *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'$':      begin
            (* DEF *)
            r.tag := readtag(fin);
            r.name := readascii(fin);
            r.defTypeForm := readtag(fin);
            readcomma(fin);
            r.defSize := readtag(fin);
            readcomma(fin);
            r.defDim := readuinteger8(fin);
            r.defFlags := readuinteger8(fin);
            r.defMode := false;

            { add the name to the name stack }
            { Needed at this point so a record format type defn can refer to itself }
            addSymbol( r.tag, r.name );

            r.assembly := formAssembly( r );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',r.assembly );

            { determine various assembler mode variables }
            if (not inStart) then
            begin
              if r.defMode then defMode := true;
            end;

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag(ficd,r.tag);
              writeascii(ficd,r.name);
              writetag(ficd,r.defTypeForm);
              writecomma(ficd);
              writetag(ficd,r.defSize);
              writecomma(ficd);
              writeuinteger8(ficd,r.defDim);
              writeuinteger8(ficd,r.defFlags);
            end;
          end;
'%':      begin
            (* XOR *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'&':      begin
            (* AND *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'''':     begin
            (* PUSHS *)
            str1 := readstring( fin );

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

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writestring( ficd, str1 );
            end;
          end;
'(':      begin
            (* JLE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
')':      begin
            (* JGE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'*':      begin
            (* MUL *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'+':      begin
            (* ADD *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'-':      begin
            (* SUB *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'.':      begin
            (* CONCAT *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'/':      begin
            (* QUOT *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
':':      begin
            (* LOCATE *)
            (* Compiler generated label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1);

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
';':      begin
            (* END *)
            finishlevels( fout );
            writeln( fout, r.mnemonic );

            popFrame();

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'<':      begin
            (* JL *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'=':      begin
            (* JE *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'>':      begin
            (* JG *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'?':      begin
//            (* JUMPIF *)
            (* COMPARE VALUES *)
//            (* JUMP FORWARD to Compiler label *)
//            str1 := toTest(readchar(fin));
//            uint1 := readtag(fin);

            tablevels( fout );
//            writeln( fout, r.mnemonic,' ',str1,' $',uint1 );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
//              writechar( ficd, fromTest( str1 ) );
//              writetag( ficd, uint1 );
            end;
          end;
'@':      begin
            (* PUSH *)
            uint1 := readtag(fin);
            str1 := lookupTag(uint1);

            tablevels( fout );
            writeln( fout, r.mnemonic,' "',str1,'"' );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, lookupsymbol( str1 ) );
            end;
          end;
'A':      begin
            (* INIT *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'B':      begin
            (* REPEAT *)
            (* JUMP BACKWARD to Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writetag( ficd, uint1 );
            end;
          end;
'C':      begin
            (* JUMPIFA *)
            (* COMPARE ADDRESSES *)
            (* JUMP FORWARD to Compiler label *)
//            str1 := toTest(readchar(fin));
//            uint1 := readtag(fin);

            tablevels( fout );
//            writeln( fout, r.mnemonic,' ',str1,' $',uint1 );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
//              writechar( ficd, fromTest( str1 ) );
//              writetag( ficd, uint1 );
            end;
          end;
'D':      begin
            (* PUSHR *)
            str1 := readfloat(fin,int1);

            if (int1 = 0) then
            begin
              tablevels( fout );
              write( fout, r.mnemonic,' ',str1 );
              if debugFlag then write( fout, ' aka ',iCodeFloatToDouble(str1,0));
              writeln( fout );
            end
            else
            begin
              tablevels( fout );
              write( fout, r.mnemonic,' ',str1, '@', int1 );
              if debugFlag then write( fout, ' aka ',iCodeFloatToDouble(str1,int1));
              writeln( fout );
            end;

            if debugFlag then
            begin
              d := icodeFloatToDouble( str1, int1 );
              str1 := doubleToIcodeMantissa( d );
              int1 := doubleToIcodeExponent( d );

              writeinst( ficd, r.icode );
              writefloat( ficd, str1, int1 );
            end;
          end;
'E':      begin
            (* CALL *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'F':      begin
            (* GOTO *)
            (* JUMP FORWARD to Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'G':      begin
            (* ALIAS *)
            str1 := readstring(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' "',str1,'"' );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writestring( ficd, str1 );
            end;
          end;
'H':      begin
            (* BEGIN *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            pushFrame;

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'J':      begin
            (* JUMP *)
            (* JUMP to User label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' L',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'K':      begin
            (* FALSE *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'L':      begin
            (* LABEL *)
            (* User label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' L',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'M':      begin
            (* MAP *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'N':      begin
            (* PUSHI *)
            int1 := readinteger32( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',int1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeinteger32( ficd, int1 );
            end;
          end;
'O':      begin
            (* LINE *)
            uint1 := readtag(fin);

            { don't indent the LINE operator }
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'P':      begin
            (* PLANT *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'Q':      begin
            (* DIVIDE *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'R':      begin
            (* RETURN *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'S':      begin
            (* ASSVAL *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'T':      begin
            (* TRUE *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'U':      begin
            (* NEGATE *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'V':      begin
            (* RESULT *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'W':      begin
            (* SJUMP *)
            (* SWITCH jump *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'X':      begin
            (* IEXP *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'Y':      begin
            (* DEFAULT *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'Z':      begin
            (* ASSREF *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'[':      begin
            (* LSH *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'\':      begin
            (* NOT *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
']':      begin
            (* RSH *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'^':      begin
            (* SET-FORMAT *)
            uint1 := readtag(fin);
            str1 := lookupTag(uint1);

            tablevels( fout );
            writeln( fout, r.mnemonic,' ', str1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, lookupsymbol(str1) );
            end;
          end;
'_':      begin
            (* SLABEL *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'a':      begin
            (* ACCESS *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'b':      begin
            (* BOUNDS *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'd':      begin
            (* DIM *)
            uint1 := readtag(fin);
            readcomma(fin);
            uint2 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1,',',uint2 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
              writeComma( ficd );
              writeTag( ficd, uint2 );
            end;
          end;
'e':      begin
            (* EVENT *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'f':      begin
            (* FOR *)
            (* Compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
// g
// h
'i':      begin
            (* INDEX *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'j':      begin
            (* JAM *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'k':      begin
            (* JZ *)
            (* JUMP FORWARD to compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'l':      begin
            (* LANG *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'm':      begin
            (* MONITOR *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'n':      begin
            (* SELECT *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'o':      begin
            (* ON *)
            (* On event Jump to compiler label *)
            uint1 := readtag( fin );
            readcomma( fin );
            uint2 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1,' $',uint2 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
              writeComma( ficd );
              writeTag( ficd, uint2 );
            end;
          end;
'p':      begin
            (* ASSPAR *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'q':      begin
            (* SUBA *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'r':      begin
            (* RESOLVE *)
            uint1 := readtag( fin );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
's':      begin
            (* STOP *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
't':      begin
            (* JNZ *)
            (* JUMP FORWARD to compiler label *)
            uint1 := readtag(fin);

            tablevels( fout );
            writeln( fout, r.mnemonic,' $',uint1 );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, uint1 );
            end;
          end;
'u':      begin
            (* ADDA *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'v':      begin
            (* MOD *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'w':      begin
            (* MCODE *)
            r.str1 := getascii( fin, ';' );
            r.assembly := formAssembly( r );

            tablevels( fout );
            writeln( fout, r.mnemonic,' ', r.assembly );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              putascii( ficd, r.str1, ';' );
            end;
          end;
'x':      begin
            (* REXP *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'y':      begin
            (* DIAG *)
            b1 := 255 and readuinteger8( fin );
            b2 := 255 and readuinteger8( fin );
            passId := (b1 shr 6) and $3;
            passValue := ((b1 and $3f) shl 8) + b2;

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',passId,',',passValue );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, (passId shl 14) + PassValue );
            end;

          end;
'z':      begin
            (* CONTROL *)
            b1 := 255 and readuinteger8( fin );
            b2 := 255 and readuinteger8( fin );
            passId := (b1 shr 6) and $3;
            passValue := ((b1 and $3f) shl 8) + b2;

            tablevels( fout );
            writeln( fout, r.mnemonic,' ',passId,',',passValue );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writeTag( ficd, (passId shl 14) + PassValue );
            end;
          end;
'{':      begin
            (* START *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            (* gtype indicates if record format/routine def/routine spec *)
            (* set by preceding DEF *)
            pushFrame;
            inStart := true;

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'|':      begin
            (* ALT_PSR *)
            tablevels( fout );
            writeln( fout, r.mnemonic );

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'}':      begin
            (* FINISH *)
            finishlevels( fout );
            writeln( fout, r.mnemonic );

            if not defMode then
            begin
              popframe;
            end;
            inStart := false;
            defMode := false;

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
            end;
          end;
'~':      begin
            (* ALT *)
            altMode := readchar(fin);

            tablevels( fout );
            case altMode of
        'A':  writeln( fout, r.mnemonic,' BEGIN');
        'B':  writeln( fout, r.mnemonic,' END');
        'C':  writeln( fout, r.mnemonic,' NEXT');
            else
            end;

            if debugFlag then
            begin
              writeinst( ficd, r.icode );
              writechar( ficd, altMode );
            end;
          end;
        else
        end;

      end;
    end;

  end;

  procedure help();
  begin
    writeln('ICD2ASSEMBLE: 2 or 3 parameters expected:');
    writeln('First 2 parameters <icode input> <assembler output>');
    writeln('Third parameter indicates additional debug information');
    writeln('e.g. icd2assemble [icodefile] [iasmfile] -debug');
  end;

begin
  if ((ParamCount = 3) and (ParamStr(3) = '-debug')) or (ParamCount = 2) then
  begin
    if FileExists( ParamStr(1) ) then
    begin
      debugFlag := ((ParamCount = 3) and (ParamStr(3) = '-debug'));

      assign( fin, ParamStr( 1 ) );
      assign( fout, ParamStr( 2 ) );
      reset( fin );
      rewrite( fout );

      if debugFlag then
      begin
        assign( ficd, ParamStr( 1 )+ '.v' );
        rewrite( ficd );
      end;

      lineno := 0;
      inStart := false;
      defMode := false;
      initSymStack;

      pushFrame;
      disassemble();

      close(fin);
      close(fout);

      if debugFlag then
      begin
        write( ficd, 10 );
        close(ficd);
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