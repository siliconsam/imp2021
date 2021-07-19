{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit icdio;
interface
uses
  dos,
  math,
  sysutils,
  strutils;
type
  integer8 = ShortInt;
  uinteger8 = Byte;
  integer16 = SmallInt;
  uinteger16 = Word;
  integer32 = LongInt;
  uinteger32 = LongWord;
  ficode = file of uinteger8;

  function GetFilePath( fileName : string ) : string;
  function GetFileName( fileName : string ) : string;
  function GetFileExt( fileName : string ) : string;
  function GetProgramPath : string;
  { ICD read routines }
  function readtag( var f : ficode): uinteger16;
  function readinteger16( var f : ficode ): integer16;
  function readinteger32( var f : ficode): integer32;
  function readuinteger32( var f : ficode): uinteger32;
  function readuinteger8( var f : ficode ): uinteger8;
  function readchar( var f : ficode ): char;
  function readstring( var f : ficode ): string;
  function readfloat( var f: ficode; var expo : integer32 ): string;
  function getascii( var f : ficode; terminator : char ): string;
  function readascii( var f : ficode ): string;
  procedure readcomma( var f : ficode );
  { ICD write routines }
  procedure writebyte( var f : ficode; i : uinteger32 );
  procedure writetag( var f : ficode; i : uinteger16 );
  procedure writeinteger( var f : ficode; i : uinteger32 );
  procedure writestring( var f : ficode; s : string );
  procedure writecomma( var f : ficode );
  procedure putascii( var f : ficode; s : string; terminator : char );
  procedure writeascii( var f : ficode; s : string);
  procedure writeinteger16( var f : ficode; i : integer16 );
  procedure writefloat( var f: ficode; s : string; expo : integer16 );
  procedure writeinst( var f : ficode; inst : char );
  procedure writeinteger32( var f : ficode; i : integer32 );
  procedure writechar( var f : ficode; c : char );
  procedure writeuinteger8( var f : ficode; u : uinteger8 );
  { ICD utility code }
  function toTest( ch : char ): string;
  function fromTest( s : string ): char;
  function doubleToIcodeMantissa( d : double ): string;
  function doubleToIcodeExponent( d : double ): integer16;
  function icodeFloatToDouble( m : string; e : integer16 ): double;

implementation

type
  intbyte =
  record
    case boolean of
      false: (i : uinteger32);
      true:  (b0: byte; b1: byte; b2: byte; b3: byte);
  end;

  function GetFilePath( fileName : string ) : string;
  var
    d,n,e : string;
  begin
    FSplit(fileName,d,n,e);
    GetFilePath := d;
  end;

  function GetFileName( fileName : string ) : string;
  var
    d,n,e : string;
  begin
    FSplit(fileName,d,n,e);
    GetFileName := n;
  end;

  function GetFileExt( fileName : string ) : string;
  var
    d,n,e : string;
  begin
    FSplit(fileName,d,n,e);
    GetFileExt := e;
  end;

  function GetProgramPath : string;
  begin
    GetProgramPath := GetFilePath(ParamStr(0));
  end;

  function readtag( var f : ficode): uinteger16;
  type
    uint16byte =
    record
      case boolean of
      false: (i : uinteger16);
      true:  (b0: byte; b1: byte);
    end;
  var
    x : uint16byte;
  begin
    read( f, x.b1, x.b0 );
    readtag := x.i;
  end;

  function readinteger16( var f : ficode ): integer16;
  type
    int16byte =
    record
      case boolean of
      false: (i : integer16);
      true:  (b0: byte; b1: byte);
    end;
  var
    x : int16byte;
  begin
    read( f, x.b1, x.b0 );
    readinteger16 := x.i;
  end;

  function readinteger32( var f : ficode): integer32;
  type
    int32byte =
    record
      case boolean of
      false: (i : integer32);
      true:  (b0: byte; b1: byte; b2: byte; b3: byte);
    end;
  var
    x : int32byte;
  begin
    read( f, x.b3, x.b2, x.b1, x.b0 );
    readinteger32 := x.i;
  end;

  function readuinteger32( var f : ficode): uinteger32;
  type
    uint32byte =
    record
      case boolean of
      false: (i : uinteger32);
      true:  (b0: byte; b1: byte; b2: byte; b3: byte);
    end;
  var
    x : uint32byte;
  begin
    read( f, x.b3, x.b2, x.b1, x.b0 );
    readuinteger32 := x.i;
  end;

  function readuinteger8( var f : ficode ): uinteger8;
  var
    b : uinteger8;
  begin
    read( f , b );
    readuinteger8 := b;
  end;

  function readchar( var f : ficode ): char;
  begin
    readchar := chr( readuinteger8( f ) );
  end;

  function readstring( var f : ficode ): string;
  var
    s : string;
    i,slen : uinteger8;
  begin
    slen := readuinteger8( f );
    s := '';
    for i := 1 to slen do
    begin
      s := s + readchar( f );
    end;
    readstring := s;
  end;

  function readfloat( var f: ficode; var expo : integer32 ): string;
  var
    s : string;
    ch : char;
    slen : uinteger16;
  begin
    slen := readtag(f);
    ch := readchar( f ); (* Skip over the comma *)
    (* initialise the decimal and exponent values *)
    s := '';
    expo := 0;

    (* now grab the decimal part. *)
    (* Warning: the slen value represents the length of decimal + optional 2 bytes for the exponent *)
    (* The @ char is NOT included in the count *)
    repeat
      ch := readchar( f );
      slen := slen - 1;
      if (ch <> '@') then s := s + ch;
    until (ch = '@') or (slen = 0);
    if (slen <> 0) then
    begin
      (* So we should have found an @ char, meaning we need to read the exponent tag *)
      (* get the exponent *)
      expo := readinteger16(f);
    end;
    (* A float value is always positive *)
    (* The ICODE 'U' - for NEGATE will follow if we want a negative float value *)
    readfloat := s;
  end;

  function getascii( var f : ficode; terminator : char ): string;
  var
    s : string;
    b : byte;
  begin
    s := '';
    repeat
      read( f, b );
      if (b <> ord( terminator)) then s := s + chr(b);
    until b = ord( terminator );
    getascii := s;
  end;

  function readascii( var f : ficode ): string;
  begin
    readascii := getascii( f, ',' );
  end;

  procedure readcomma( var f : ficode );
  var
    b : byte;
  begin
    read( f , b );
    if (chr(b) <> ',') then
    begin
      writeln('Comma expected. Found "',chr(b),'" instead');
    end;
  end;

  procedure writebyte( var f : ficode; i : uinteger32 );
  var
    x : intbyte;
  begin
    x.i := i;
    write( f, x.b0 );
  end;

  procedure writetag( var f : ficode; i : uinteger16 );
  type
    uint16byte =
    record
      case boolean of
        false: (i : uinteger16);
        true:  (b0: byte; b1: byte);
    end;
  var
    x : uint16byte;
  begin
    x.i := i;
    write( f, x.b1, x.b0 );
  end;

  procedure writeinteger( var f : ficode; i : uinteger32 );
  var
    x : intbyte;
  begin
    x.i := i;
    write( f, x.b3, x.b2, x.b1, x.b0 );
  end;

  procedure writestring( var f : ficode; s : string );
  var
    x : intbyte;
    i : integer;
  begin
    x.i := 0;
    x.i := length( s );
    write( f, x.b0 );
    for i := 1 to length(s) do
    begin
      write( f, ord(s[i]) );
    end;
  end;

  procedure writecomma( var f : ficode );
  begin
    write( f , ord(',') );
  end;

  procedure putascii( var f : ficode; s : string; terminator : char );
  var
    i : integer;
  begin
    for i := 1 to length(s) do
    begin
      write(f,ord(s[i]));
    end;
    write( f, ord(terminator) );
  end;

  procedure writeascii( var f : ficode; s : string);
  var
    i : integer;
  begin
    for i := 1 to length(s) do
    begin
      write(f,ord(s[i]));
    end;
    writecomma(f);
  end;

  procedure writeinteger16( var f : ficode; i : integer16 );
  type
    int16byte =
    record
      case boolean of
      false: (i : integer16);
      true:  (b0: byte; b1: byte);
    end;
  var
    x : int16byte;
  begin
    x.i := i;
    write( f, x.b1, x.b0 );
  end;

  procedure writefloat( var f: ficode; s : string; expo : integer16 );
  var
    i : integer;
  begin
    if (expo = 0) then
    begin
      writetag(f,length(s));

      write( f, ord( ',' ) );
      for i := 1 to length(s) do
      begin
        write( f, ord(s[i]) );
      end;
    end
    else
    begin
      writetag(f,length(s) + 2);

      write( f, ord( ',' ) );
      for i := 1 to length(s) do
      begin
        write( f, ord(s[i]) );
      end;

      write( f, ord( '@' ) );
      writeinteger16(f,expo);
    end;
  end;

  procedure writeinst( var f : ficode; inst : char );
  begin
    write( f, ord( inst ) );
  end;

  procedure writeinteger32( var f : ficode; i : integer32 );
  type
    int32byte =
    record
      case boolean of
      false: (i : integer32);
      true:  (b0: byte; b1: byte; b2: byte; b3: byte);
    end;
  var
    x : int32byte;
  begin
    x.i := i;
    write( f, x.b3, x.b2, x.b1, x.b0 );
  end;

  procedure writechar( var f : ficode; c : char );
  type
    charbyte =
    record
      case boolean of
      false: (c : char);
      true:  (b : byte);
    end;
  var
    x : charbyte;
  begin
    x.c := c;
    write( f, x.b );
  end;

  procedure writeuinteger8( var f : ficode; u : uinteger8 );
  type
    charbyte =
    record
      case boolean of
      false: (u : uinteger8);
      true:  (b : byte);
    end;
  var
    x : charbyte;
  begin
    x.u := u;
    write( f, x.b );
  end;

  function toTest( ch : char ): string;
  var
    theTest : string;
  begin
    case ch of
'>':    theTest := '>';
'<':    theTest := '<';
'=':    theTest := '=';
'(':    theTest := '<=';
')':    theTest := '>=';
'#':    theTest := '<>';
    else
      theTest := '**** UNKNOWN TEST ****';
    end;
    toTest := theTest;
  end;

  function fromTest( s : string ): char;
  var
    c : char;
  begin
    if pos('<=',s) = 1 then c := '('
    else
    if pos('>=',s) = 1 then c := ')'
    else
    if pos('<>',s) = 1 then c := '#'
    else
    if pos('>',s) = 1 then c := '>'
    else
    if pos('<',s) = 1 then c := '<'
    else
    if pos('=',s) = 1 then c := '='
    else
      c := '?';

    fromTest := c;
  end;

  function doubleToIcodeMantissa( d : double ): string;
  var
    m : float;
  begin
    m := frac(log10(d));

    if (m < 0.0) then
    begin
      m := m + 1.0;
    end;

    doubleToIcodeMantissa := FloatToStr( power( 10.0, m ) );
  end;

  function doubleToIcodeExponent( d : double ): integer16;
  var
    m : float;
    e : integer;
  begin
    m := frac(log10(d));
    e := trunc(log10(d));

    if (m < 0.0) then
    begin
      e := e - 1;
    end;

    doubleToIcodeExponent := e;
  end;

  function impFloatToDouble( rs : string ): double;
  var
    ints : string;
    decs : string;
    exps : string;
    dotloc : integer;
    atloc : integer;
    noErrorFlag : boolean;
    
    inti : int64;
    expi : int64;
    d : double;
  begin
    { ints is string before decimal point == integer part }
    { decs is string after decimal point and before @ == fractional part }
    { exps is string after @ == exponent }
    noErrorFlag := true; { ass-u-me no errors! }
    d := 0.0; { give a default value - in case of any errors }

    { Let's start by finding the decimal point and @ locations }
    { if pos give 0 result then required sub-string is NOT present }
    dotloc := pos('.',rs);
    atloc := pos('@',rs);

    { Check for a decimal point }
    case (dotLoc > 0) of
false:
      begin
        { No decimal point found }
        { Next, check for an @ }
        case (atloc > 0) of
  false:
          begin
            { no @ for exponent found }
            { so, rs is of form nnn i.e. a pure integer }
            ints := rs;
            decs := '';
            exps := '';
          end;
   true:
          begin
            { @ for exponent found }
            { so, rs has form nnn@nn, again a pure integer }
            ints := copy(rs,1,atloc - 1);
            decs := '';
            exps := copy(rs,atloc + 1,length(rs) - atloc);
          end;
        end;
      end;
true:
      begin
        { decimal point found }
        { Next, check for an @ }
        case (atloc > 0) of
  false:
          begin
            { no @ for exponent found }
            { so, rs of form nnn.nn }
            ints := copy(rs,1,dotloc - 1);
            decs := copy(rs,dotloc + 1, length(rs) - atloc);
            exps := '';
          end;
   true:
          begin
            { @ for exponent found }
            { BUT, are the decimal point and @ in the correct order }
            { Expect decimal point BEFORE @ }
            if (dotLoc < atLoc) then
            begin
              ints := copy(rs,1,dotloc - 1);
              decs := copy(rs,dotloc + 1, atloc - (dotloc + 1));
              exps := copy(rs,atloc + 1,length(rs) - atloc);
            end
            else
            begin
              { drat error, the @ is before the decimal point }
              noErrorFlag := false;
            end;
          end;
        end;
      end;
    end;

    if noErrorFlag then
    begin
      { Ok, we have 3 strings (possible 1,2 being empty) }
      { representing integer part, decimal part and exponent part }
      { Convert exponent string to an integer }
      if (exps <> '') then expi := StrToInt(exps) else expi := 0;
      { We will now form a large integer by concatenating ints and decs }
      { but we need to tweak the exponent by the length of decs }
      expi := expi - length(decs);
      inti := StrToInt(ints+decs);
      
      { ok, we have converted rs into ordered pair (inti,expi) }
      { But we want a double }
      { So we need to first form a double from inti }
      d := inti;
      { Now to incorporate the value of the exponent, expi }
      if (expi <> 0) then
      begin
        { ok, non-zero exponent }
        if (expi > 0) then
        begin
          { positive exponent }
          while (expi > 0) do
          begin
            expi := expi - 1;
            d := d * 10;
          end;
        end
        else
        begin
          { negative exponent }
          expi := -expi;
          while (expi > 0) do
          begin
            expi := expi - 1;
            d := d / 10;
          end;
        end;
      end;
    end;

    impFloatToDouble := d;
  end;

  function icodeFloatToDouble( m : string; e : integer16 ): double;
  begin
    icodeFloatToDouble := impFloatToDouble( m+'@'+IntToStr(e) );
  end;

end.