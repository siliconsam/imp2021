{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit symTable;
interface

type
  uinteger16 = Word;

  procedure initSymStack;
  procedure pushFrame;
  procedure popFrame;
  procedure tablevels( var f : text );
  procedure finishlevels( var f : text );
  procedure addSymbol( theTag : uinteger16; theName : string );
  function pushSymbol( theName : string ): uinteger16;
  function lookupSymbol( theName : string ): uinteger16;
  function lookupTag( theTag : uinteger16 ): string;
  function lookupTagIndex( theTag : uinteger16 ): uinteger16;

implementation
const
  symMax = 4095;
  labMax = 127;

type
  symRange = 0..symMax;
  symrec =
  record
    tag : uinteger16;
    name : string;
  end;
  symStackRec =
  record
    frameLevel : symRange;
    frame : array [symRange] of symRange;
    topSym : symRange;
    symTab : array[symRange] of symrec;
  end;

  labRange = 0..labMax;
  labRec =
  record
    tag : uinteger16;
    labId : uinteger16;
  end;
  labTableRec =
  record
    topLab : labRange;
    labTab : array[labRange] of labRec;
  end;

var
  symStack : symStackRec;

  procedure initSymStack;
  begin
    symStack.topSym := 0;
    symStack.frameLevel := 0;
  end;

  function getFrameLevel : symRange;
  begin
    getFrameLevel := symStack.frameLevel;
  end;

  procedure pushFrame;
  begin
    symStack.frameLevel := symStack.frameLevel + 1;
    symStack.frame[symStack.frameLevel] := symStack.topSym;
  end;

  procedure popFrame;
  begin
    symStack.topSym := symStack.frame[symStack.frameLevel];
    symStack.frameLevel := symStack.frameLevel - 1;
  end;

  procedure tablevels( var f : text );
  var
    i,fl : symRange;
  begin
    fl := getFrameLevel;
    for i := 1 to fl do
    begin
      write( f, '  ' );
    end;
  end;

  procedure finishlevels( var f : text );
  var
    i,fl : symRange;
  begin
    fl := getFrameLevel() - 1;
    for i := 1 to fl do
    begin
      write( f, '  ' );
    end;
  end;

  procedure addSymbol( theTag : uinteger16; theName : string );
  begin
    symStack.topSym := symStack.topSym + 1;
    symStack.symTab[symStack.topSym].tag := theTag;
    symStack.symTab[symStack.topSym].name := theName;
  end;

  function pushSymbol( theName : string ): uinteger16;
  begin
    symStack.topSym := symStack.topSym + 1;
    symStack.symTab[symStack.topSym].tag := symStack.topSym;
    symStack.symTab[symStack.topSym].name := theName;

    pushSymbol := symStack.topSym;
  end;

  function lookupSymbol( theName : string ): uinteger16;
  var
    i : symRange;
    n : uinteger16;
  begin
    n := 0;
    i := 1;
    for i := symStack.topSym downto 1 do
    begin
      if (n = 0) and (symStack.symTab[i].name = theName) then
      begin
        n := symStack.symTab[i].tag;
      end;
    end;
    lookupsymbol := n;
  end;

  function lookupTag( theTag : uinteger16 ): string;
  var
    i : symRange;
    s : string;
  begin
    s := '';
    i := 1;
    for i := symStack.topSym downto 1 do
    begin
      if (s = '') and (symStack.symTab[i].tag = theTag) then
      begin
        s := symStack.symTab[i].name;
      end;
    end;
    lookupTag := s;
  end;

  function lookupTagIndex( theTag : uinteger16 ): uinteger16;
  var
    s : uinteger16;
    i : symRange;
  begin
    s := 0;
    i := 1;
    for i := symStack.topSym downto 1 do
    begin
      if (s = 0) and (symStack.symTab[i].tag = theTag) then
      begin
        s := i;
      end;
    end;
    lookupTagIndex := s;
  end;

end.