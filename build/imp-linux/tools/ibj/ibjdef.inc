!  %endoflist
{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
  ! Intermediate file types:
  %constbyteinteger IF OBJ        =  0; ! plain object code
  %constbyteinteger IF DATA       =  1; ! dataseg offset code word
  %constbyteinteger IF CONST      =  2; ! const seg offset code word
  %constbyteinteger IF DISPLAY    =  3; ! display seg offset code word
  %constbyteinteger IF JUMP       =  4; ! unconditional jump to label
  %constbyteinteger IF JCOND      =  5; ! cond jump to label JE, JNE, JG, JGE, JL, JLE, JA, JAE, JB, JBE
  %constbyteinteger IF CALL       =  6; ! call a label
  %constbyteinteger IF LABEL      =  7; ! define a label
  %constbyteinteger IF FIXUP      =  8; ! define location for stack fixup instruction
  %constbyteinteger IF SETFIX     =  9; ! stack fixup <location> <amount>
  %constbyteinteger IF REQEXT     = 10; ! external name spec
  %constbyteinteger IF REFLABEL   = 11; ! reference a label address
  %constbyteinteger IF REFEXT     = 12; ! external name relative offset code word
  %constbyteinteger IF BSS        = 13; ! BSS segment offset code word
  %constbyteinteger IF COTWORD    = 14; ! Constant table word
  %constbyteinteger IF DATWORD    = 15; ! Data segment word
  %constbyteinteger IF SWTWORD    = 16; ! switch table entry - actually a label ID
  %constbyteinteger IF SOURCE     = 17; ! name of the source file
  %constbyteinteger IF DEFEXTCODE = 18; ! define a code label that is external
  %constbyteinteger IF DEFEXTDATA = 19; ! define a data label that is external
  %constbyteinteger IF SWT        = 20; ! switch table offset code word
  %constbyteinteger IF LINE       = 21; ! line number info for debugger
  %constbyteinteger IF ABSEXT     = 22; ! external name absolute offset code word (data external)

  %conststring(16)%array ibj name(IF OBJ:IF ABSEXT) = "IF_OBJ",
                                                      "IF_DATA",
                                                      "IF_CONST",
                                                      "IF_DISPLAY",
                                                      "IF_JUMP",
                                                      "IF_JCOND",
                                                      "IF_CALL",
                                                      "IF_LABEL",
                                                      "IF_FIXUP",
                                                      "IF_SETFIX",
                                                      "IF_REQEXT",
                                                      "IF_REFLABEL",
                                                      "IF_REFEXT",
                                                      "IF_BSS",
                                                      "IF_COTWORD",
                                                      "IF_DATWORD",
                                                      "IF_SWTWORD",
                                                      "IF_SOURCE",
                                                      "IF_DEFEXTCODE",
                                                      "IF_DEFEXTDATA",
                                                      "IF_SWT",
                                                      "IF_LINE",
                                                      "IF_ABSEXT"

  %conststring(16)%array condition name(0:5) = "JE",
                                               "JNE",
                                               "JG",
                                               "JGE",
                                               "JL",
                                               "JLE"

%endoffile
