{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit ibjutil;
interface
uses ibjdef;

const

    WORDSIZE = 4; // wordsize in bytes

    IF_NULL        = -1; // used to guard against empty item list
    IF_OBJ         =  0; // A : plain object code
    IF_DATA        =  1; // B : dataseg offset code word
    IF_CONST       =  2; // C : const seg offset code word
    IF_DISPLAY     =  3; // D : display seg offset code word
    IF_JUMP        =  4; // E : unconditional jump to label
    IF_JCOND       =  5; // F : cond jump to label JE, JNE, JG, JGE, JL, JLE, JA, JAE, JB, JBE
    IF_CALL        =  6; // G : call a label
    IF_LABEL       =  7; // H : define a label
    IF_FIXUP       =  8; // I : define location for stack fixup instruction
    IF_SETFIX      =  9; // J : stack fixup <location> <amount>
    IF_REQEXT      = 10; // K : external name spec
    IF_REFLABEL    = 11; // L : reference a label address
    IF_REFEXT      = 12; // M : external name relative offset code word
    IF_BSS         = 13; // N : BSS segment offset code word
    IF_COTWORD     = 14; // O : Constant table word
    IF_DATWORD     = 15; // P : Data segment word
    IF_SWTWORD     = 16; // Q : switch table entry - actually a label ID
    IF_SOURCE      = 17; // R : name of the source file
    IF_DEFEXTCODE  = 18; // S : define a code label that is external
    IF_DEFEXTDATA  = 19; // T : define a data label that is external
    IF_SWT         = 20; // U : switch table offset code word
    IF_LINE        = 21; // V : line number info for debugger
    IF_ABSEXT      = 22; // W : external name absolute offset code word (data external)

  function IBJcode( x : string ): integer;
  function IBJname( x : integer ): string;
  function TestCode( t : string ): integer;
  function TestName( t : integer ): string;
  function formnibble( x : integer) : char;
  function formbyte( x : integer ): string;
  function formword( x : integer ): string;
  function forminteger( x : integer ): string;
  function formstring( x : string ): string;
  function readnibble( c : char) : integer;
  function readbyte( theData : string ): integer;
  function readword( theData : string ): integer;
  function readinteger( theData : string ): integer;
  function readascii( theData : string ): string;
  procedure readirecord( var f : text; var theType : integer; var theCount : integer; var theData : string );
  procedure writeirecord( var f : text; theType : integer; theCount : integer; theData : string );

implementation

  function IBJcode( x : string ): integer;
  var
    c : integer;
  begin
    case x of
'IF_OBJ':        c := IF_OBJ;
'IF_DATA':       c := IF_DATA;
'IF_CONST':      c := IF_CONST;
'IF_DISPLAY':    c := IF_DISPLAY;
'IF_JUMP':       c := IF_JUMP;
'IF_JCOND':      c := IF_JCOND;
'IF_CALL':       c := IF_CALL;
'IF_LABEL':      c := IF_LABEL;
'IF_FIXUP':      c := IF_FIXUP;
'IF_SETFIX':     c := IF_SETFIX;
'IF_REQEXT':     c := IF_REQEXT;
'IF_REFLABEL':   c := IF_REFLABEL;
'IF_REFEXT':     c := IF_REFEXT;
'IF_BSS':        c := IF_BSS;
'IF_COTWORD':    c := IF_COTWORD;
'IF_DATWORD':    c := IF_DATWORD;
'IF_SWTWORD':    c := IF_SWTWORD;
'IF_SOURCE':     c := IF_SOURCE;
'IF_DEFEXTCODE': c := IF_DEFEXTCODE;
'IF_DEFEXTDATA': c := IF_DEFEXTDATA;
'IF_SWT':        c := IF_SWT;
'IF_LINE':       c := IF_LINE;
'IF_ABSEXT':     c := IF_ABSEXT;
      else
        c := IF_NULL; // invalid IBJ code value
      end;
    IBJCode := c;
  end;

  function IBJName( x : integer ): string;
  var
    c : string;
  begin
    case x of
IF_OBJ:        c := 'IF_OBJ';
IF_DATA:       c := 'IF_DATA';
IF_CONST:      c := 'IF_CONST';
IF_DISPLAY:    c := 'IF_DISPLAY';
IF_JUMP:       c := 'IF_JUMP';
IF_JCOND:      c := 'IF_JCOND';
IF_CALL:       c := 'IF_CALL';
IF_LABEL:      c := 'IF_LABEL';
IF_FIXUP:      c := 'IF_FIXUP';
IF_SETFIX:     c := 'IF_SETFIX';
IF_REQEXT:     c := 'IF_REQEXT';
IF_REFLABEL:   c := 'IF_REFLABEL';
IF_REFEXT:     c := 'IF_REFEXT';
IF_BSS:        c := 'IF_BSS';
IF_COTWORD:    c := 'IF_COTWORD';
IF_DATWORD:    c := 'IF_DATWORD';
IF_SWTWORD:    c := 'IF_SWTWORD';
IF_SOURCE:     c := 'IF_SOURCE';
IF_DEFEXTCODE: c := 'IF_DEFEXTCODE';
IF_DEFEXTDATA: c := 'IF_DEFEXTDATA';
IF_SWT:        c := 'IF_SWT';
IF_LINE:       c := 'IF_LINE';
IF_ABSEXT:     c := 'IF_ABSEXT';
      else
        c := 'IF_NULL'; // invalid IBJ code value
      end;
    IBJName := c;
  end;

  function TestCode( t : string ): integer;
  var
    c : integer;
  begin
    case t of
 'JE':  c := 0;
'JNE':  c := 1;
 'JG':  c := 2;
'JGE':  c := 3;
 'JL':  c := 4;
'JLE':  c := 5;
 'JA':  c := 6;
'JAE':  c := 7;
 'JB':  c := 8;
'JBE':  c := 9;
    else
      c := -1;
    end;
    TestCode := c;
  end;

  function TestName( t : integer ): string;
  var
    s : string;
  begin
    case t of
  0:  s :=  'JE';
  1:  s := 'JNE';
  2:  s :=  'JG';
  3:  s := 'JGE';
  4:  s :=  'JL';
  5:  s := 'JLE';
  6:  s :=  'JA';
  7:  s := 'JAE';
  8:  s :=  'JB';
  9:  s := 'JBE';
    else
      s := '???';
    end;
    TestName := s;
  end;

  function formnibble( x : integer) : char;
  var
    ch : char;
    n : integer;
  begin
    n := x and 15;
    if (0 <= n) and (n <= 9) then ch := chr( ord('0') + n );
    if (10 <= n) and (n <= 15) then ch := chr( ord('A') + n - 10);
    formnibble := ch;
  end;

  function formbyte( x : integer ): string;
  begin
    formbyte := formnibble( x shr 4 ) + formnibble( x );
  end;

  function formword( x : integer ): string;
  begin
    formword := formbyte( x ) + formbyte( x shr 8 );
  end;

  function forminteger( x : integer ): string;
  begin
    forminteger := formbyte( x ) + formbyte( x shr 8 ) + formbyte( x shr 16 ) + formbyte( x shr 24 );
  end;

  function formstring( x : string ): string;
  var
    s : string;
    i,j : integer;
  begin
    s := '';
    for i := 1 to length(x) do
    begin
      j := ord( x[i] );
      s := s + formbyte( j );
    end;
    formstring := s;
  end;

  function readnibble( c : char) : integer;
  var
    x : integer;
  begin
    x := 0;
    if ('0' <= c) and (c <= '9') then x := ord(c) - ord('0');
    if ('a' <= c) and (c <= 'f') then x := 10 + ord(c) - ord('a');
    if ('A' <= c) and (c <= 'F') then x := 10 + ord(c) - ord('A');
    readnibble := x;
  end;

  function readbyte( theData : string ): integer;
  var
    b0 : integer;
  begin
    b0 := (readnibble( theData[1] ) shl 4) + readnibble( theData[2] );

    readbyte := b0;
  end;

  function readword( theData : string ): integer;
  var
    b0, b1 : integer;
  begin
    b0 := (readnibble( theData[1] ) shl 4) + readnibble( theData[2] );
    b1 := (readnibble( theData[3] ) shl 4) + readnibble( theData[4] );

    readword := (b1 shl 8) + b0;
  end;

  function readinteger( theData : string ): integer;
  var
    b0, b1, b2, b3 : integer;
  begin
    b0 := (readnibble( theData[1] ) shl 4) + readnibble( theData[2] );
    b1 := (readnibble( theData[3] ) shl 4) + readnibble( theData[4] );
    b2 := (readnibble( theData[5] ) shl 4) + readnibble( theData[6] );
    b3 := (readnibble( theData[7] ) shl 4) + readnibble( theData[8] );

    readinteger := (b3 shl 24) + (b2 shl 16) + (b1 shl 8) + b0;
  end;

  function readascii( theData : string ): string;
  var
    s : string;
    i : integer;
  begin
    s := '';
    for i := 1 to length(theData) div 2 do
    begin
      s := s + chr( 16*readnibble( theData[2*i - 1] ) + readnibble( theData[2*i] ) );
    end;
    readascii := s;
  end;

  procedure readirecord( var f : text; var theType : integer; var theCount : integer; var theData : string );
  var
    arec : string;
  begin
    readln( f, arec );
    theType := ord(arec[1]) - ord('A');

    theCount := readbyte( copy(arec,2,length( arec ) - 1 ) );
    theData := copy( arec, 4, length( arec ) - 3 );
  end;

  procedure writeirecord( var f : text; theType : integer; theCount : integer; theData : string );
  var
    arec : string;
  begin
    arec := chr( theType + ord('A') ) + formByte( (length( theData ) shr 1) and 255 ) + theData;

    writeln( f, arec );
  end;

end.