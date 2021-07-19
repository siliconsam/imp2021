{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit ibjdef;
interface
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

type
    tCond = (cNULLCond
            ,cJE
            ,cJNE
            ,cJG
            ,cJGE
            ,cJL
            ,cJLE
            ,cJA
            ,cJAE
            ,cJB
            ,cJBE
            );

    tIBJ = (cNULLIbj
           ,cOBJ
           ,cDATA
           ,cCONST
           ,cDISPLAY
           ,cJUMP
           ,cJCOND
           ,cCALL
           ,cLABEL
           ,cFIXUP
           ,cSETFIX
           ,cREQEXT
           ,cREFLABEL
           ,cREFEXT
           ,cBSS
           ,cCOTWORD
           ,cDATWORD
           ,cSWTWORD
           ,cSOURCE
           ,cDEFEXTCODE
           ,cDEFEXTDATA
           ,cSWT
           ,cLINE
           ,cABSEXT
           );

    tOBJ =
    record
        code : string;
    end;

    tDATA =
    record
        longdata : array [1..4] of byte;
    end;

    tCONST =
    record
        longdata : array [1..4] of byte;
    end;

    tDISPLAY =
    record
        longdata : array [1..4] of byte;
    end;

    tJUMP =
    record
        labelNo : integer;
    end;

    tJCOND =
    record
        condition : byte;
        labelNo : integer;
    end;

    tCALL =
    record
        labelNo : integer;
    end;

    tLABEL =
    record
        labelNo : integer;
    end;

    tFIXUP =
    record
        fixupId : integer;
        level   : integer;
        name    : string;
    end;

    tSETFIX =
    record
        fixupid : integer;
        value   : integer;
        events  : integer;
        trap    : integer;
        evfrom  : integer;
    end;

    tREQEXT =
    record
        name : string;
    end;

    tREFLABEL =
    record
        labelNo : integer;
        offset  : integer;
    end;

    tREFEXT =
    record
        specId : integer;
        offset : integer;
    end;

    tBSS =
    record
        longdata : array [1..4] of byte;
    end;

    tCOTWORD =
    record
        shortdata : array [1..2] of byte;
    end;

    tDATWORD =
    record
        shortdata : array [1..2] of byte;
    end;

    tSWTWORD =
    record
        labelNo : integer;
    end;

    tSOURCE =
    record
        name : string;
    end;

    tDEFEXTCODE =
    record
        name : string;
    end;

    tDEFEXTDATA =
    record
        name : string;
    end;

    tSWT =
    record
        longdata : array [1..4] of byte;
    end;

    tLINE =
    record
        sourcelineno : integer;
    end;

    tABSEXT =
    record
        specId : integer;
        offset : integer;
    end;

    tIBJPtr = ^tIBJRec;
    tIBJRec =
    record
        top    : tIBJPtr;
        before : tIBJPtr;
        follow : tIBJPtr;
        lineno : integer;
    case t : tIBJ of
        cNULLibj:    ( );
        cOBJ:        ( xOBJ        : tOBJ; );
        cDATA:       ( xDATA       : tDATA; );
        cCONST:      ( xCONST      : tCONST; );
        cDISPLAY:    ( xDISPLAY    : tDISPLAY; );
        cJUMP:       ( xJUMP       : tJUMP; );
        cJCOND:      ( xJCOND      : tJCOND; );
        cCALL:       ( xCALL       : tCALL; );
        cLABEL:      ( xLABEL      : tLABEL; );
        cFIXUP:      ( xFIXUP      : tFIXUP; );
        cSETFIX:     ( xSETFIX     : tSETFIX; );
        cREQEXT:     ( xREQEXT     : tREQEXT; );
        cREFLABEL:   ( xREFLABEL   : tREFLABEL );
        cREFEXT:     ( xREFEXT     : tREFEXT; );
        cBSS:        ( xBSS        : tBSS; );
        cCOTWORD:    ( xCOTWORD    : tCOTWORD; );
        cDATWORD:    ( xDATWORD    : tDATWORD; );
        cSWTWORD:    ( xSWTWORD    : tSWTWORD; );
        cSOURCE:     ( xSOURCE     : tSOURCE; );
        cDEFEXTCODE: ( xDEFEXTCODE : tDEFEXTCODE; );
        cDEFEXTDATA: ( xDEFEXTDATA : tDEFEXTDATA; );
        cSWT:        ( xSWT        : tSWT; );
        cLINE:       ( xLINE       : tLINE; );
        cABSEXT:     ( xABSEXT     : tABSEXT; );
    end;

implementation

    function IBJType( x : char ): tIBJ;
    var
        c : tIBJ;
    begin
        case x of
        'A': c := cOBJ;
        'B': c := cDATA;
        'C': c := cCONST;
        'D': c := cDISPLAY;
        'E': c := cJUMP;
        'F': c := cJCOND;
        'G': c := cCALL;
        'H': c := cLABEL;
        'I': c := cFIXUP;
        'J': c := cSETFIX;
        'K': c := cREQEXT;
        'L': c := cREFLABEL;
        'M': c := cREFEXT;
        'N': c := cBSS;
        'O': c := cCOTWORD;
        'P': c := cDATWORD;
        'Q': c := cSWTWORD;
        'R': c := cSOURCE;
        'S': c := cDEFEXTCODE;
        'T': c := cDEFEXTDATA;
        'U': c := cSWT;
        'V': c := cLINE;
        'W': c := cABSEXT;
        else
            c := cNULLibj; // invalid IBJ code value
        end;
        IBJType := c;
    end;

    function IBJcode( x : string ): tIBJ;
    var
        c : tIBJ;
    begin
        case x of
        'IF_OBJ':        c := cOBJ;
        'IF_DATA':       c := cDATA;
        'IF_CONST':      c := cCONST;
        'IF_DISPLAY':    c := cDISPLAY;
        'IF_JUMP':       c := cJUMP;
        'IF_JCOND':      c := cJCOND;
        'IF_CALL':       c := cCALL;
        'IF_LABEL':      c := cLABEL;
        'IF_FIXUP':      c := cFIXUP;
        'IF_SETFIX':     c := cSETFIX;
        'IF_REQEXT':     c := cREQEXT;
        'IF_REFLABEL':   c := cREFLABEL;
        'IF_REFEXT':     c := cREFEXT;
        'IF_BSS':        c := cBSS;
        'IF_COTWORD':    c := cCOTWORD;
        'IF_DATWORD':    c := cDATWORD;
        'IF_SWTWORD':    c := cSWTWORD;
        'IF_SOURCE':     c := cSOURCE;
        'IF_DEFEXTCODE': c := cDEFEXTCODE;
        'IF_DEFEXTDATA': c := cDEFEXTDATA;
        'IF_SWT':        c := cSWT;
        'IF_LINE':       c := cLINE;
        'IF_ABSEXT':     c := cABSEXT;
        else
            c := cNULLibj; // invalid IBJ code value
        end;
        IBJCode := c;
    end;

    function IBJName( x : tIBJ ): string;
    var
        c : string;
    begin
        case x of
        cOBJ:        c := 'IF_OBJ';
        cDATA:       c := 'IF_DATA';
        cCONST:      c := 'IF_CONST';
        cDISPLAY:    c := 'IF_DISPLAY';
        cJUMP:       c := 'IF_JUMP';
        cJCOND:      c := 'IF_JCOND';
        cCALL:       c := 'IF_CALL';
        cLABEL:      c := 'IF_LABEL';
        cFIXUP:      c := 'IF_FIXUP';
        cSETFIX:     c := 'IF_SETFIX';
        cREQEXT:     c := 'IF_REQEXT';
        cREFLABEL:   c := 'IF_REFLABEL';
        cREFEXT:     c := 'IF_REFEXT';
        cBSS:        c := 'IF_BSS';
        cCOTWORD:    c := 'IF_COTWORD';
        cDATWORD:    c := 'IF_DATWORD';
        cSWTWORD:    c := 'IF_SWTWORD';
        cSOURCE:     c := 'IF_SOURCE';
        cDEFEXTCODE: c := 'IF_DEFEXTCODE';
        cDEFEXTDATA: c := 'IF_DEFEXTDATA';
        cSWT:        c := 'IF_SWT';
        cLINE:       c := 'IF_LINE';
        cABSEXT:     c := 'IF_ABSEXT';
        else
            c := 'IF_NULL'; // invalid IBJ code value
        end;
        IBJName := c;
    end;

    function TestType( i : integer ): tCond;
    var
        s : tCond;
    begin
        case i of
        0:  s := cJE;
        1:  s := cJNE;
        2:  s := cJG;
        3:  s := cJGE;
        4:  s := cJL;
        5:  s := cJLE;
        6:  s := cJA;
        7:  s := cJAE;
        8:  s := cJB;
        9:  s := cJBE;
        else
            s := cNULLcond;
        end;
        TestType := s;
    end;

    function TestCode( t : string ): tCond;
    var
        c : tCond;
    begin
        case t of
        'JE':   c := cJE;
        'JNE':  c := cJNE;
        'JG':   c := cJG;
        'JGE':  c := cJGE;
        'JL':   c := cJL;
        'JLE':  c := cJLE;
        'JA':   c := cJA;
        'JAE':  c := cJAE;
        'JB':   c := cJB;
        'JBE':  c := CJBE;
        else
            c := cNullcond;
        end;
        TestCode := c;
    end;

    function TestName( t : tCond ): string;
    var
        s : string;
    begin
        case t of
        cJE:   s :=  'JE';
        cJNE:  s := 'JNE';
        cJG:   s :=  'JG';
        cJGE:  s := 'JGE';
        cJL:   s :=  'JL';
        cJLE:  s := 'JLE';
        cJA:   s :=  'JA';
        cJAE:  s := 'JAE';
        cJB:   s :=  'JB';
        cJBE:  s := 'JBE';
        else
            s := '???';
        end;
        TestName := s;
    end;

    function formnibble( x : integer ) : char;
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
        b : integer;
    begin
        b := (readnibble( theData[1] ) shl 4) + readnibble( theData[2] );

        readbyte := b;
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

    procedure parseirecord( sequence : integer; arec : string );
    var
        theSize   : integer;
        theData   : string;
        theIBJ    : tIBJPtr;
        errorFlag : boolean;
        offset    : longint;

        procedure checkSize( expectedSize : integer );
        begin
            if (theSize <> expectedSize) then
            begin
                writeln(       '**** ERROR **** @',theIBJ^.lineno,': ',ibjName(theIBJ^.t),' - Oops - length screwup!');
                errorFlag := true;
            end;
        end;

    begin
        theSize := readbyte( copy(arec,2,length( arec ) - 1 ) );
        theData := copy( arec, 4, length( arec ) - 3 );

        new( theIBJ );
        theIBJ^.t := IBJType( arec[1] );
        theIBJ^.lineno := sequence;

        case theIBJ^.t of
        cOBJ:
            begin
                // plain object code
                theIBJ^.xObj.code := theData;
            end;
        cDATA:
            begin
                // dataseg offset word
                checkSize( WORDSIZE );
                theIBJ^.xData.longdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xData.longdata[2] := readByte( copy(theData, 3, 2 ) );
                theIBJ^.xData.longdata[3] := readByte( copy(theData, 5, 2 ) );
                theIBJ^.xData.longdata[4] := readByte( copy(theData, 7, 2 ) );
            end;
        cCONST:
            begin
                // const seg offset word
                checkSize( WORDSIZE );
                theIBJ^.xCONST.longdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xCONST.longdata[2] := readByte( copy(theData, 3, 2 ) );
                theIBJ^.xCONST.longdata[3] := readByte( copy(theData, 5, 2 ) );
                theIBJ^.xCONST.longdata[4] := readByte( copy(theData, 7, 2 ) );
            end;
        cDISPLAY:
            begin
                // display seg offset word
                checkSize( WORDSIZE );
                theIBJ^.xDISPLAY.longdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xDISPLAY.longdata[2] := readByte( copy(theData, 3, 2 ) );
                theIBJ^.xDISPLAY.longdata[3] := readByte( copy(theData, 5, 2 ) );
                theIBJ^.xDISPLAY.longdata[4] := readByte( copy(theData, 7, 2 ) );
            end;
        cJUMP:
            begin
                // unconditional jump to label
                theIBJ^.xJUMP.labelNo := readword( theData ); // target label number
            end;
        cJCOND:
            begin
                // cond jump to label JE, JNE, JLE, JL, JGE, JG
                theIBJ^.xJCOND.condition := readbyte( copy( theData, 1, 2) );
                theIBJ^.xJCOND.labelNo := readword( copy( theData, 3, 4) ); // target label number
            end;
        cCALL:
            begin
                // call a label
                theIBJ^.xCALL.labelNo := readword( copy( theData, 1, 4 ) ); // target label number
            end;
        cLABEL:
            begin
                // define a label
                theIBJ^.xLABEL.labelNo := readword( copy( theData, 1, 4) );
            end;
        cFIXUP:
            begin
                // define location for stack fixup instruction
                theIBJ^.xFIXUP.fixupId := readword( copy( theData, 1,4 ) ); // id number for fixup
                theIBJ^.xFIXUP.level := readbyte( copy(theData,5,2 ) );
                theIBJ^.xFIXUP.name := readAscii( copy( theData, 7, length(theData) - 6) );
            end;
        cSETFIX:
            begin
                // stack fixup <location> <amount> <eventmask> <event entry>
                theIBJ^.xSETFIX.fixupId := readword( copy( theData, 1,4 ) );	            // id number for fixup
                // compiler passes value as a 16 bit negative number but we make it positive
                theIBJ^.xSETFIX.value   :=  (- readword( copy( theData, 5,4 ) )) and $ffff; // positive! amount to subtract
                theIBJ^.xSETFIX.events  := readword( copy( theData, 9,4 ) );                // on events
                theIBJ^.xSETFIX.trap    := readword( copy( theData, 13,4 ) );               // trap
                theIBJ^.xSETFIX.evfrom  := readword( copy( theData, 17,4 ) );               // on events
            end;
        cREQEXT:
            begin
                // external name spec
                theIBJ^.xREQEXT.name := readAscii( theData );
            end;
        cREFLABEL:
            begin
                // call a label
                theIBJ^.xREFLABEL.labelNo := readword( copy( theData, 1, 4 ) ); // target label number
                offset  := readword( copy( theData, 5, 4 ) ); // target label offset
                if (offset > 32767) then
                begin
                    theIBJ^.xREFLABEL.offset := -65535 + offset;
                end
                else
                begin
                    theIBJ^.xREFLABEL.offset := offset;
                end;
            end;
        cREFEXT:
            begin
                // external name relative offset code word
                checkSize( WORDSIZE );
                theIBJ^.xREFEXT.specId := readword( copy( theData, 1, 4 ) ); // reference index
                theIBJ^.xREFEXT.offset := readword( copy( theData, 5, 8 ) ); // relative offset
            end;
        cBSS:
            begin
                // BSS segment offset code word
                checkSize( WORDSIZE );
                theIBJ^.xBSS.longdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xBSS.longdata[2] := readByte( copy(theData, 3, 2 ) );
                theIBJ^.xBSS.longdata[3] := readByte( copy(theData, 5, 2 ) );
                theIBJ^.xBSS.longdata[4] := readByte( copy(theData, 7, 2 ) );
            end;
        cCOTWORD:
            begin
                // Constant table word
                checkSize( WORDSIZE div 2 );
                theIBJ^.xCOTWORD.shortdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xCOTWORD.shortdata[2] := readByte( copy(theData, 3, 2 ) );
            end;
        cDATWORD:
            begin
                // Data segment word
                checkSize( WORDSIZE div 2 );
                theIBJ^.xDATWORD.shortdata[1] := readByte( copy(theData, 1, 2 ) );
                theIBJ^.xDATWORD.shortdata[2] := readByte( copy(theData, 3, 2 ) );
            end;
        cSWTWORD:
            begin
                // switch table entry - actually a label ID
                checkSize( WORDSIZE div 2 );
                theIBJ^.xSWTWORD.labelNo := readword( theData ); // target label number
            end;
        cSOURCE:
            begin
                // name of the source file (generated by Imp Compiler PASS2)
                theIBJ^.xSOURCE.name := readAscii( theData );
            end;
        cDEFEXTCODE:
            begin
                // define a code label that is external
                theIBJ^.xDEFEXTCODE.name := readAscii( theData );
            end;
        cDEFEXTDATA:
            begin
                // define a data label that is external
                theIBJ^.xDEFEXTDATA.name := readAscii( theData );
            end;
        cSWT:
            begin
                // SWITCH table segment offset code word
                theIBJ^.xSWT.longdata[1] := readbyte( copy( theData, 1,2 ) );
                theIBJ^.xSWT.longdata[2] := readbyte( copy( theData, 3,2 ) );
                theIBJ^.xSWT.longdata[3] := readbyte( copy( theData, 5,2 ) );
                theIBJ^.xSWT.longdata[4] := readbyte( copy( theData, 7,2 ) );
            end;
        cLINE:
            begin
                // line number info for the debugger
                theIBJ^.xLINE.sourcelineNo := readword(copy(theData,1,4)); // get the source line number
            end;
        cABSEXT:
            begin
                // external name relative offset code word
                // external name absolute offset code word (data external)
                checkSize( WORDSIZE );
                // The IMP77 compiler PASS2 program generates an ABSEXT record
                // where the actual offset is added to the specId
                theIBJ^.xABSEXT.specId := readword( copy( theData, 5, 4 ) ) ;
                theIBJ^.xABSEXT.offset := readword( copy( theData, 1, 4 ) ) - theIBJ^.xABSEXT.specId;
            end;
        else
        end;
    end;

end.