{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
(*
**** FOLLOWING is an extract from PhD Thesis of
Peter Salkeld Robertson
"The production of Optimised Machine-Code for High-Level Languages using Machine-Independent Intermediate-Codes"
Edinburgh University Thesis CST-13-81 (November 1981)

                 The IMP Intermediate Code
                      A Brief Summary
                      
   The IMP intermediate code may be considered a sequence of
instructions to a  stack-oriented  machine  which  generates
programs  for  specific computers.   It is important to note
that the intermediate code describes the compilation process
necessary to generate an executable form of  a  program;  it
does  not  directly  describe the computation defined by the
program.

   The machine which accepts the intermediate code  has  two
main components:

1          A   Descriptor  area.    This  is  used  to  hold
           descriptors     containing      machine-dependent
           definitions  of  the  objects  the  program is to
           manipulate.    This  area  is  maintained  in   a
           block-structured fashion, that is new descriptors
           are  added to the area during the definition of a
           block and are removed from the area at the end of
           the block.

2          A Stack.   The stack holds copies of  descriptors
           taken  from  the descriptor area or the parameter

           area, or created specially.   Items on the  stack
           are  modified  by intermediate code control items
           to reflect operations  specified  in  the  source
           program.   Such  modifications  may  or  may  not
           result in code being generated.   From the  point
           of  view  of  this  definition stack elements are
           considered to have at least three components:
                   i       Type
                   ii      Value
                   iii     Access rule
           The "Access rule"  defines  how  the  "Type"  and
           "Value" attributes are to interpreted in order to
           locate the described object.
           For example, the access rule for a constant could
           be  "Value  contains  the  constant"  while for a
           variable it could be "Value contains the  address
           of the variable".   Clearly, the access rules are
           target-machine  dependent.   Descriptors  may  be
           combined  to give fairly complex access rules, as
           in the case of applying "PLUS" to the stack  when
           the  top  two  descriptors are for the variable X
           and the constant 1 resulting  in  one  descriptor
           with the access rule "take the value in X and add
           1  to it".   The complexity of these access rules
           may be restricted by a  code-generator.   In  the
           example above code could be generated to evaluate
           X+1  resulting in an access rule "the value is in
           register 1", say.

   The importance of the  code  not  describing  the  actual
computation  which  the  source  program  specified  but the
compilation process required is seen when attempting to  use
the code for statements of the form:

   A := if B = C then D else E;

This could not be encoded as:

         PUSH   A
         PUSH   B
         PUSH   C
         JUMP # L1
         PUSH   D
         BR     L2
         LOC    L1
         PUSH   E
         LOC    L2
         ASSVAL
         
The reason is that the items on the stack at the time of the
ASSVAL  would be (from top to bottom) [E], [D], [A], because
no items were given which would remove them from the  stack.
hence  the  ASSVAL would assign the value of E to D and then
leave A dangling on the stack.

   Unless   otherwise   stated,   all   constants   in   the
intermediate code are represented in octal.

Descriptors

DEF TAG TEXT TYPE FORM SIZE SPEC PREFIX
           This item causes a new descriptor to be generated
           and placed in the descriptor area.   On creation,
           the  various  fields  of  the  DEF  are  used  to
           construct  the  machine-dependent  representation
           required for the object.
           TAG             is an identification  which  will
                           be  used subsequently to refer to
                           the descriptor.
           TEXT            is the source-language identifier
                           given  to  the  object  (a   null
                           string   if   no  identifier  was
                           specified).
           TYPE            is  the  type  of   the   object:
                           GENERAL,  INTEGER,  REAL, STRING,
                           RECORD, LABEL, SWITCH, FORMAT.
           FORM            is one of: SIMPLE, NAME, ROUTINE,
                           FN,  MAP,  PRED,  ARRAY,  NARRAY,
                           ARRAYN, NARRAYN.
           SIZE            is   either   the   TAG   of  the
                           appropriate     record     format
                           descriptor   for   records,   the
                           maximum  length   of   a   string
                           variable,  or  the  precision  of
                           numerical   variables:   DEFAULT,
                           BYTE, SHORT. LONG.

           SPEC            has   the   value  SPEC  or  NONE
                           depending on whether or  not  the
                           item is a specification.
           PREFIX          is  one  of:  NONE,  OWN,  CONST,
                           EXTERNAL, SYSTEM, DYNAMIC,  PRIM,
                           PERM  or SPECIAL.   If SPECIAL is
                           given  there   will   follow   an
                           implementation-dependent
                           specification  of  the properties
                           of the object (such as that it is
                           to be a register, for example).

Parameters and Formats

   The parameters for procedures and the elements of  record
formats  are  defined  by  a  list immediately following the
procedures or format descriptor definition:

START            Start of definition list

FINISH           End of definition list

ALTBEG           Start of alternative sequence

ALT              Alternative separator

ALTEND           End of alternative sequence.

Blocks

BEGIN            Start of BEGIN block

END              End of BEGIN block or procedure

PUSH <tag>       Push a copy of the  descriptor  <tag>  onto
                 the stack.

PROC <tag>       This  is  the  same as PUSH except that the
                 descriptor  being  stacked   represents   a
                 procedure  which  is  about  to  be  called
                 (using ENTER).

PUSHI <n>        Push a descriptor for the integer  constant
                 <n> onto the stack.

PUSHR <r>        Push    a    descriptor    for   the   real
                 (floating-point)  constant  <r>  onto   the
                 stack.

PUSHS <s>        Push  a  descriptor for the string constant
                 <s> onto the stack.
                 
SELECT <tag>     TOS will be  a  descriptor  for  a  record.
                 Replace this descriptor with one describing
                 the sub-element <tag> of this record.

Assignment

ASSVAL           Assign  the  value  described by TOS to the
                 variable described by SOS.   Both  TOS  and
                 SOS are popped from the stack.

ASSREF           Assign  a reference to (the address of) the
                 variable described by TOS  to  the  pointer
                 variable  described  by SOS.   Both TOS and
                 SOS are popped from the stack.

JAM              This is the same as ASSVAL except that  the
                 value  being  assigned will be truncated if
                 necessary.

ASSPAR           Assign the actual  parameter  described  by
                 TOS  to  the  formal parameter described by
                 SOS.   This is equivalent to either  ASSVAL
                 (for   value  parameters)  or  ASSREF  (for
                 reference parameters).

RESULT           TOS describes the result of  the  enclosing
                 function.   Following the processing of the
                 result code must  be  generated  to  return
                 from the function.

MAP              Similar to RESULT except that TOS describes
                 the  result of a MAP.   Again a return must
                 be generated.
                 
DEFAULT <n>

INIT <n>         Create N data items, corresponding  to  the
                 last descriptor defined, and given them all
                 an initial (constant) value.   The constant
                 is popped from the stack  in  the  case  of
                 INIT      but    DEFAULT    causes      the
                 machine-dependent default value to be  used
                 (normally the UNASSIGNED pattern).

Binary operators

ADD              Addition
SUB              Subtraction
MUL              Multiplication
QUOT             Integer division
DIVIDE           Real division
IEXP             Integer exponentiation
REXP             Real exponentiation
AND              Logical AND
OR               Logical inclusive OR
XOR              Logical exclusive OR
LSH              Logical left shift
RSH              Logical right shift
CONC             String concatenate
ADDA             ++
SUBA             --

   The given operation is performed on TOS and SOS , both of
which   are   removed   from   the  stack,  and  the  result
(SOS op TOS) is pushed onto the stack.
e.g.  A = B-C

      PUSH   A
      PUSH   B
      PUSH   C
      SUB ASSVAL

Unary Operators

NEG              Negate (unary minus)

NOT              Logical NOT (complement)

MOD              Modulus (absolute value)

The given operation is performed on TOS.

Arrays

DIM <d> <n>      The  stack  will  contain  <d>   pairs   of
                 descriptors  corresponding to the lower and
                 upper   bounds   for   an   array.     This
                 information is used to construct <n> arrays
                 and any necessary accessing information for
                 use  through  the  last  <n> descriptors to
                 have   been   defined.     All   of   these
                 descriptors will be for similar arrays.

INDEX            SOS   will   be   the   descriptor   for  a
                 multi-dimensional array and TOS will be the
                 next non-terminal subscript.   The stack is
                 popped.

ACCESS           SOS  will be the descriptor of an array and
                 TOS will be the final/only subscript.  Both
                 descriptors are replaced  by  a  descriptor
                 for the appropriate element of the array.
                 E.g.  given  arrays A(1:5) and B(1:4, 2:6),
                 and integers J,K:

                    A(J) = 0      K = B(J, K)

                    PUSH   A      PUSH K
                    PUSH   J      PUSH B
                    ACCESS        PUSH J
                    PUSHC  0      INDEX
                    ASSVAL        PUSH K
                                  ACCESS
                                  ASSIGN                   

Internal labels

                    Internal labels are those labels in  the
                 intermediate  code  which have been created
                 by the  process  of  translating  from  the
                 source   program,  and  so  do  not  appear
                 explicitly in the source program.  The main
                 property of these labels is that they  will
                 only be referred to once.  This fact can be
                 used   to  re-use  these  labels,  as,  for
                 example,   a   forward   reference   to   a
                 currently-defined   label  must  cause  its
                 redefinition.

LOCATE <1>       define internal label <1>

GOTO <1>         forward jump to internal label <1>

REPEAT <1>       backward jump to internal label <1>

Conditional branches

   These branches are always forward.

JUMPIF           <cond> <label>
JUMPIFD          <cond> <label>
JUMPIFA          <cond> <label>
                    Where:   <cond> ::= =, #,
                                        <, <=,
                                        >, >=,
                                        TRUE, FALSE

   The two items on the top of the stack are compared and  a
jump  is  taken  to  <label>  is  the condition specified by
<cond> is true.   In the case of <cond> being TRUE or  FALSE
only one item is taken from the stack, and this represents a
boolean value to be tested.

User Labels

LABEL <d>        locate label descriptor <d>

JUMP <d>         Jump to the label described by <d>

CALL <d>         Call the procedure described by <d>

Sundry Items

ON <e> <l>       Start   of   event  trap  for  events  <e>.
                 Internal label <l> defines the end  of  the
                 event block.

EVENT <e>        Signal event <e>

STOP             stop

MONITOR          monitor

RESOLVE <m>      Perform a string resolution

FOR              Start of a for loop

SLABEL <sd>      Define switch label

SJUMP <sd>       Select and jump to switch label

LINE <l>         Set the current line number to <l>


     !   OR            G   ALIAS         c   MCODE
     "   JUMPIFD       H   BEGIN         d   DIM
     #   BNE           I   unused        e   EVENT
     $   DEF           J   JUMP          f   FOR
     %   XOR           K   FALSE         g   unused
     &   AND           L   LABEL         h   ALTBEG
     '   PUSHS         M   MAP           i   INDEX
     (   unused        N   PUSHI         j   JAM
     )   unused        O   LINE          k   unused
     *   MUL           P   PLANT         l   LANG
     +   ADD           Q   DIVIDE        m   MONITOR
     -   SUB           R   RETURN        n   SELECT
     .   CONCAT        S   ASSVAL        o   ON
     /   QUOT          T   TRUE          p   ASSPAR
     :   LOCATE        U   NEGATE        q   ALTEND
     ;   END           V   RESULT        r   RESOLVE
     <   unused        W   SJUMP         s   STOP
     =   unused        X   IEXP          t   unused
     >   unused        Y   DEFAULT       u   ADDA
     ?   JUMPIF        Z   ASSREF        v   MOD
     @   PUSH          [   LSH           w   SUBA
     A   INIT          \   NOT           x   REXP
     B   REPEAT        ]   RSH           y   DIAG
     C   JUMPIFA       ^   PROC          z   CONTROL
     D   PUSHR         _   SLABEL        {   START
     E   CALL          a   ACCESS        |   ALT
     F   GOTO          b   BOUNDS        }   FINISH

*)
(*
Pass2 Compiler (Intel 386)

    !   OR          G   ALIAS        *c   MCODE
    "   COMPARED    H   BEGIN         d   DIM
    #   JNE         I   PASCAL??      e   EVENT
    $   DEF         J   JUMP          f   FOR
    %   XOR         K   FALSE         g   DIM duplicate??
    &   AND         L   LABEL        *h   ALTBEG
    '   PUSHS       M   MAP           i   INDEX
    (   JLE         N   PUSHI         j   JAM
    )   JGE         O   LINE          k   JZ
    *   MUL        *P   PLANT(unused) l   LANG
    +   ADD         Q   DIVIDE        m   MONITOR
    -   SUB         R   RETURN        n   SELECT
    .   CONCAT      S   ASSVAL        o   ON
    /   QUOT        T   TRUE          p   ASSPAR
    :   LOCATE      U   NEGATE        q   SUBA
    ;   END         V   RESULT        r   RESOLVE
    <   JL          W   SJUMP         s   STOP
    =   JE          X   IEXP          t   JNZ
    >   JG         *Y   DEFAULT       u   ADDA
    ?   COMPARE     Z   ASSREF        v   MOD
    @   PUSH        [   LSH          *w   MCODE?  Machine Code
    A   INIT        \   NOT           x   REXP
    B   REPEAT      ]   RSH           y   DIAG
    C   COMPAREA    ^   PROC          z   CONTROL
    D   PUSHR       _   SLABEL        {   START
    E   CALL        a   ACCESS       *|   unused
    F   GOTO        b   BOUNDS        }   FINISH
                                      ~A  ALTBEG
                                      ~B  ALTEND
                                      ~C  ALTNEXT

*)

unit icoderec;
interface

type
  tIcodeRec =
  packed record
    mnemonic : string;
    assembly : string;
    case icode : char of
chr(10),
'!','"','%','&',
'*','+','-','.',
'/',';','?','C',
'E','H','K','M',
'P','Q','R','S',
'T','U','V','X',
'Z','[','\',']',
'a','b','i','j',
'm','p','q','s',
'u','v','x','{',
'|','}':          ();
'#','(',')',':',
'<','=','>','A',
'B','F','J','L',
'O','W','Y','_',
'e','f','k','l',
'n','r','t','y',
'z':              ( d : word; );
'''','G','w':     ( str1 : string; );
'd','g','o':      ( d1, d2 : shortint; );
'@','^','D':      ( t : shortint; s : string; );
'$':              ( tag : word; name : string; defTypeForm,defSize : word; defDim,defFlags : byte; defMode : boolean );
'N':              ( n : longint; );
'~':              ( ch : char; );
chr(255):         ();
  end;

  function intelReg( s : string ): integer;
  function newRecByMnemonic( m : string ): tIcodeRec;
  function newRecByChar( c : char ): tIcodeRec;
  function formAssembly( var y : tIcodeRec): string;

implementation
uses
  sysutils,
  symTable;

const
  eax=1;
  ecx=2;
  edx=3;
  ebx=4;
  esi=5;
  edi=6;
  esp=7;
  ebp=8;

  function intelReg( s : string ): integer;
  var
    regId : integer;
  begin
    regId := -1;
    s := copy( s, 1, 3 );
    case upcase(s) of
'EAX': regId := eax;
'ECX': regId := ecx;
'EBX': regId := ebx;
'EDX': regId := edx;
'ESI': regId := esi;
'EDI': regId := edi;
'ESP': regId := esp;
'EBP': regId := ebp;
    else
      regId := -1;
    end;
    intelReg := regId;
  end;

  function mnemonic2code( m : string ): char;
  var
    ch : char;    
  begin
    case m of
'ENDOFFILE': ch := chr(10);
'OR':        ch := '!';
'COMPARED':  ch := '"';
'JNE':       ch := '#';
'DEF':       ch := '$';
'XOR':       ch := '%';
'AND':       ch := '&';
'PUSHS':     ch := '''';
'JLE':       ch := '(';
'JGE':       ch := ')';
'MUL':       ch := '*';
'ADD':       ch := '+';
'SUB':       ch := '-';
'CONCAT':    ch := '.';
'QUOT':      ch := '/';
'LOCATE':    ch := ':';
'END':       ch := ';';
'JL':        ch := '<';
'JE':        ch := '=';
'JG':        ch := '>';
'COMPARE':   ch := '?';
'PUSH':      ch := '@';
'INIT':      ch := 'A';
'REPEAT':    ch := 'B';
'JUMPIFA':   ch := 'C';
'PUSHR':     ch := 'D';
'CALL':      ch := 'E';
'GOTO':      ch := 'F';
'ALIAS':     ch := 'G';
'BEGIN':     ch := 'H';
// I
'JUMP':      ch := 'J';
'FALSE':     ch := 'K';
'LABEL':     ch := 'L';
'MAP':       ch := 'M';
'PUSHI':     ch := 'N';
'LINE':      ch := 'O';
'PLANT':     ch := 'P';
'DIVIDE':    ch := 'Q';
'RETURN':    ch := 'R';
'ASSVAL':    ch := 'S';
'TRUE':      ch := 'T';
'NEGATE':    ch := 'U';
'RESULT':    ch := 'V';
'SJUMP':     ch := 'W';
'IEXP':      ch := 'X';
'DEFAULT':   ch := 'Y';
'ASSREF':    ch := 'Z';
'LSH':       ch := '[';
'NOT':       ch := '\';
'RSH':       ch := ']';
'SETFORMAT': ch := '^';
'SLABEL':    ch := '_';
'ACCESS':    ch := 'a';
'BOUNDS':    ch := 'b';
// c
'DIM':       ch := 'd';
'EVENT':     ch := 'e';
'FOR':       ch := 'f';
// g
// h
'INDEX':     ch := 'i';
'JAM':       ch := 'j';
'JZ':        ch := 'k';
'LANG':      ch := 'l';
'MONITOR':   ch := 'm';
'SELECT':    ch := 'n';
'ON':        ch := 'o';
'ASSPAR':    ch := 'p';
'SUBA':      ch := 'q';
'RESOLVE':   ch := 'r';
'STOP':      ch := 's';
'JNZ':       ch := 't';
'ADDA':      ch := 'u';
'MOD':       ch := 'v';
'MCODE':     ch := 'w';
'REXP':      ch := 'x';
'DIAG':      ch := 'y';
'CONTROL':   ch := 'z';
'START':     ch := '{';
'ALT_PSR':   ch := '|';
'FINISH':    ch := '}';
'ALT':       ch := '~';
    else
      ch := chr(255);
    end;

    mnemonic2code := ch;
  end;

  function code2mnemonic( c : char ): string;
  var
    m : string;    
  begin
    case c of
chr(10): m := 'ENDOFFILE';
'!':     m := 'OR';
'"':     m := 'COMPARED';
'#':     m := 'JNE';
'$':     m := 'DEF';
'%':     m := 'XOR';
'&':     m := 'AND';
'''':    m := 'PUSHS';
'(':     m := 'JLE';
')':     m := 'JGE';
'*':     m := 'MUL';
'+':     m := 'ADD';
'-':     m := 'SUB';
'.':     m := 'CONCAT';
'/':     m := 'QUOT';
':':     m := 'LOCATE';
';':     m := 'END';
'<':     m := 'JL';
'=':     m := 'JE';
'>':     m := 'JG';
'?':     m := 'COMPARE';
'@':     m := 'PUSH';
'A':     m := 'INIT';
'B':     m := 'REPEAT';
'C':     m := 'JUMPIFA';
'D':     m := 'PUSHR';
'E':     m := 'CALL';
'F':     m := 'GOTO';
'G':     m := 'ALIAS';
'H':     m := 'BEGIN';
// I
'J':     m := 'JUMP';
'K':     m := 'FALSE';
'L':     m := 'LABEL';
'M':     m := 'MAP';
'N':     m := 'PUSHI';
'O':     m := 'LINE';
'P':     m := 'PLANT';
'Q':     m := 'DIVIDE';
'R':     m := 'RETURN';
'S':     m := 'ASSVAL';
'T':     m := 'TRUE';
'U':     m := 'NEGATE';
'V':     m := 'RESULT';
'W':     m := 'SJUMP';
'X':     m := 'IEXP';
'Y':     m := 'DEFAULT';
'Z':     m := 'ASSREF';
'[':     m := 'LSH';
'\':     m := 'NOT';
']':     m := 'RSH';
'^':     m := 'SETFORMAT';
'_':     m := 'SLABEL';
'a':     m := 'ACCESS';
'b':     m := 'BOUNDS';
// c
'd':     m := 'DIM';
'e':     m := 'EVENT';
'f':     m := 'FOR';
// g
// h
'i':     m := 'INDEX';
'j':     m := 'JAM';
'k':     m := 'JZ';
'l':     m := 'LANG';
'm':     m := 'MONITOR';
'n':     m := 'SELECT';
'o':     m := 'ON';
'p':     m := 'ASSPAR';
'q':     m := 'SUBA';
'r':     m := 'RESOLVE';
's':     m := 'STOP';
't':     m := 'JNZ';
'u':     m := 'ADDA';
'v':     m := 'MOD';
'w':     m := 'MCODE';
'x':     m := 'REXP';
'y':     m := 'DIAG';
'z':     m := 'CONTROL';
'{':     m := 'START';
'|':     m := 'ALT_PSR';
'}':     m := 'FINISH';
'~':     m := 'ALT';
    else
      m := 'ILLEGAL';
    end;

    code2mnemonic := m;
  end;

  function newRecByMnemonic( m : string ): tIcodeRec;
  var
    y : tIcodeRec;    
  begin
    y.mnemonic := m;
    y.assembly := '';

    y.icode := mnemonic2code( y.mnemonic );
    if y.icode = chr(255) then y.mnemonic := 'ILLEGAL';

    newRecByMnemonic := y;
  end;

  function newRecByChar( c : char ): tIcodeRec;
  var
    y : tIcodeRec;    
  begin
    y.icode := c;
    y.assembly := '';

    y.mnemonic := code2mnemonic( c );
    if (y.mnemonic = 'ILLEGAL') then y.icode := chr(255);

    newRecByChar := y;
  end;

  function formDefAssembly( var r : tIcodeRec ): string;
  var
    s : string;
    flagstring : string;
    defType : byte;
    defForm : byte;
  begin
    s := '"' + r.name + '"' + ' AS';

    case (r.defFlags and $7) of
  0:  s := s + ' AUTO';
  1:  s := s + ' OWN';
  2:  s := s + ' CONSTANT';
  3:  s := s + ' EXTERNAL';
  4:  s := s + ' SYSTEM';
  5:  s := s + ' DYNAMIC';
  6:  s := s + ' PRIMITIVE';
  7:  s := s + ' PERMANENT';
    else
    end;

    defType := $f and (r.defTypeForm shr 4);
    case defType of
  0:  s := s + ' VOID';
  1:  case r.defSize of
    1:  s := s + ' INTEGER';
    2:  s := s + ' BYTE';
    3:  s := s + ' SHORT';
    4:  s := s + ' LONG';
    5:  s := s + ' QUAD';
      else
      end;
  2:  case r.defSize of
    1:  s := s + ' REAL';
    4:  s := s + ' DOUBLE';
      else
      end;
  3:  case r.defSize of
    0:  s := s + ' STRING(*)';
      else
        s := s + ' STRING(' + IntToStr( r.defSize ) + ')';
      end;
  4:  case r.defSize of
    0:  s := s + ' RECORD(*)';
      else
        s := s + ' RECORD("' + lookupTag( r.defSize ) + '")';
      end;
  5:  s := s + ' BOOLEAN';
  6:  s := s + ' SET';
  7:  s := s + ' ENUM8("' + lookupTag( r.defSize ) + '")';
  8:  s := s + ' ENUM16("' + lookupTag( r.defSize ) + '")';
  9:  s := s + ' POINTER';
 10:  s := s + ' CHAR';
 11:  case r.defSize of
    1:  s := s + ' UNSIGNED';
    2:  s := s + ' BYTEUNSIGNED';
    3:  s := s + ' SHORTUNSIGNED';
    4:  s := s + ' LONGUNSIGNED';
    5:  s := s + ' QUADUNSIGNED';
      else
      end;
    else
    end;

    defForm := $f and (r.defTypeForm);
    case defForm of
  0:  s := s + ' VOID';
  1:  s := s + ' SIMPLE';
  2:  s := s + ' NAME';
  3:  s := s + ' LABEL';
  4:  s := s + ' RECORDFORMAT';
  5:  ;
  6:  s := s + ' SWITCH';
  7:  s := s + ' ROUTINE';
  8:  s := s + ' FUNCTION';
  9:  s := s + ' MAP';
 10:  s := s + ' PREDICATE';
 11:  s := s + ' ARRAY';
 12:  s := s + ' ARRAYNAME';
 13:  s := s + ' NAMEARRAY';
 14:  s := s + ' NAMEARRAYNAME';
 15:  ;
    else
    end;

    { See if there are any flags set }
    flagstring := '';
    if ((r.defFlags and $08) <> 0) then
    begin
      if (length(flagstring) > 0) then flagstring := flagstring + ',';
      flagstring := flagstring + 'SPEC';
    end;
    if ((r.defFlags and $10) <> 0) then
    begin
      if (length(flagstring) > 0) then flagstring := flagstring + ',';
      flagstring := flagstring + 'INDIRECT';
    end;
    if ((r.defFlags and $20) <> 0) then
    begin
      if (length(flagstring) > 0) then flagstring := flagstring + ',';
      flagstring := flagstring + 'CHECK';
    end;
    if ((r.defFlags and $40) <> 0) then
    begin
      if (length(flagstring) > 0) then flagstring := flagstring + ',';
      flagstring := flagstring + 'B6FLAG';
    end;
    if ((r.defFlags and $80) <> 0) then
    begin
      if (length(flagstring) > 0) then flagstring := flagstring + ',';
      flagstring := flagstring + 'B7FLAG';
    end;

    { Ok, flags were set so show them }
    if (length(flagstring) > 0) then
    begin
      s := s + ' [' + flagstring + ']';
    end;

    if ((r.defFlags and $08) = 0) and (defForm in [7,8,9,10]) then r.defMode := true;

    formDefAssembly := s;
  end;

  function formMcodeAssembly( mstring : string ): string;
  var
    s : string;
    hashFlag,
    inrbFlag,
    insbFlag,
    inabFlag : boolean;
    mlen : integer;
    n : longword;
    i : integer;
  begin
    s := '';

    if (pos('_',mstring) <> 0) then
    begin
      mlen := length(mstring);
      i := pos('_',mstring);
      inrbFlag := false; // inside round bracket sequence
      insbFlag := false; // inside square bracket sequence
      inabFlag := false; // inside angle bracket sequence
      hashFlag := false;

      s := s + copy( mstring, 1, i  ) + ' ';
      i := i + 1;
      while (i <= mlen) do
      begin
        case mstring[i] of
    ' ':
          begin
            // a variable reference is prefixed by a space.
            n := 256*ord( mstring[i+1] ) + ord( mstring[i+2] );
            s := s + lookupTag( n );
            i := i + 3;
          end;
    'N':
          begin
            // A number is prefixed by an 'N'
            n := 256*( 256*( 256*ord(mstring[i+1]) + ord(mstring[i+2]) ) + ord(mstring[i+3]) ) + ord( mstring[i + 4] );
            if hashFlag then
            begin
              // hashflag indicates this is a genuine integer
              hashFlag := false;
              if (n > 127) then
              begin
                s := s + '16_' + IntToHex( n, 0 );
              end
              else
              begin
                s := s + IntToStr( n );
              end;
            end
            else
            begin
              // ok this came from a constant integer in the IMP program
              // ASS-U-ME that this constant represents a register identifier
              // So, prefix the number with an R (for register)
              // Most assemblers use that notation.
              // IMP code with embedded assembler will be for a specific instruction set
              // so the IMP pass2 for that instruction set should convert the "register" number
              // to the real register. eg Intel eax or ebp
              case n of
          eax:  s := s + 'EAX';
          ecx:  s := s + 'ECX';
          ebx:  s := s + 'EBX';
          edx:  s := s + 'EDX';
          esi:  s := s + 'ESI';
          edi:  s := s + 'EDI';
          esp:  s := s + 'ESP';
          ebp:  s := s + 'EBP';
              else
                s := s + 'R' + IntToStr( n );
              end
            end;
            i := i + 5;
          end;
chr(128)..chr(255):
          begin
            s := s + '%';
            while ord(mstring[i]) > 127 do
            begin
              s := s + chr(ord(mstring[i]) - 128);
              i := i + 1;
            end;
            s := s + ' ';
          end;
    '#':
          begin
            // let this char through
            // BUT remember # is assumed to prefix a number
            hashFlag := true;
            s := s + mstring[i];
            i := i + 1;
          end;
    ',':
          begin
            // let this char through
            // separating instruction parameters (or values between brackets)
            s := s + mstring[i];
            i := i + 1;
          end;
    '(':
          begin
            // let this char through
            // opening round brackets
            inrbFlag := true;
            s := s + mstring[i];
            i := i + 1;
          end;
    ')':
          begin
            // let this char through
            // closing round brackets
            inrbFlag := false;
            s := s + mstring[i];
            i := i + 1;
          end;
    '[':
          begin
            // let this char through
            // opening square brackets
            insbFlag := true;
            s := s + mstring[i];
            i := i + 1;
          end;
    ']':
          begin
            // let this char through
            // closing square brackets
            insbFlag := false;
            s := s + mstring[i];
            i := i + 1;
          end;
    '<':
          begin
            // let this char through
            // opening angle brackets
            inabFlag := true;
            s := s + mstring[i];
            i := i + 1;
          end;
    '>':
          begin
            // let this char through
            // closing angle brackets
            inabFlag := false;
            s := s + mstring[i];
            i := i + 1;
          end;
        else
          // let this char through
          s := s + mstring[i];
          i := i + 1;
        end;
      end;
    end
    else
    begin
      s := s + ' has bad format ';
    end;

    formMCodeAssembly := s;
  end;

  function formAssembly( var y : tIcodeRec): string;
  begin
    y.assembly := '';

    y.mnemonic := code2mnemonic( y.icode );
    case y.icode of
'$':  begin
        y.assembly := formDefAssembly( y );
      end;
'w':  begin
        y.assembly := formMcodeAssembly( y.str1 );
      end;
    else
      y.mnemonic := 'ILLEGAL';
      y.icode := chr(255);
    end;

    formAssembly := y.assembly;
  end;

 end.