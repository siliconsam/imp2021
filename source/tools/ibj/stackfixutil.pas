{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit stackfixutil;
interface
type
  tStackFixField = (cStackFixId
                   ,cStackFixHint
                   ,cStackFixEvents
                   ,cStackFixStart
                   ,cStackFixTrap
                   ,cStackFixEvFrom
                   ,cStackFixEndFn
                   ,cStackFixNameId
                   ,cStackFixLineNo
                   );

  procedure initialiseStackFix();
  function getStackFixCount(): integer;
  function newStackFix(): integer;
  procedure setStackFixField( ptr : integer; field : tStackFixField; fieldData : integer );
  function getStackFixField( ptr : integer; field : tStackFixField ): integer;
  function findStackFixById( fixupId : integer ):integer;

implementation

const
  MaxStackFix    = 500;

type
  tStackFix =
  record
    id     : integer; // arbitrary ID passed by Pass 2 (actually derived from P2's nominal code address)
    hint   : integer; // pointer to the M record corresponding to the entry code
    events : integer; // events trapped in this subroutine (a 16 bit bitmask)
    start  : integer; // actual start address of subroutine
    trap   : integer; // label of the event trap entry point (if events != 0)
    evfrom : integer; // label of the start of the event protected area
    endfn  : integer; // actual end address of subroutine **** pass3.c field name is "end"
    namep  : integer; // pointer to debug name of this routine

    lineno : integer; // IBJ file source line number
  end;

  tStackFixArray =
  record
    count : 0..MaxStackFix;
    data  : array [0..MaxStackFix] of tStackFix;
  end;

var
  Stacks : tStackFixArray;

  procedure initialiseStackFix();
  begin
    Stacks.count := 0;
  end;

  function getStackFixCount(): integer;
  begin
    getStackFixCount := Stacks.count;
  end;

  function newStackFix(): integer;
  begin
    if (Stacks.count = MaxStackFix) then
    begin
      writeln( 'Program/module too big' );
      writeln( 'Increase the value of MaxStack. (Currently ',MaxStackFix,')' );
      halt(1);

      newStackFix := MaxStackFix + 1;;
    end
    else
    begin
      Stacks.count := Stacks.count + 1;
      Stacks.data[Stacks.count].id     := -1; // id number for fixup
      Stacks.data[Stacks.count].hint   := -1; // point to this code item
      Stacks.data[Stacks.count].events := 0;  // assume no events trapped
      Stacks.data[Stacks.count].trap   := 0;  // no label
      Stacks.data[Stacks.count].namep  := -1; // debug name
      Stacks.data[Stacks.count].lineNo := -1; // IBJ source file line number

      newStackFix := Stacks.count;
    end;
  end;

  procedure setStackFixField( ptr : integer; field : tStackFixField; fieldData : integer );
  begin
    case field of
cStackFixId:     Stacks.data[ptr].id     := fieldData;
cStackFixHint:   Stacks.data[ptr].hint   := fieldData;
cStackFixEvents: Stacks.data[ptr].events := fieldData;
cStackFixStart:  Stacks.data[ptr].start  := fieldData;
cStackFixTrap:   Stacks.data[ptr].trap   := fieldData;
cStackFixEvFrom: Stacks.data[ptr].evfrom := fieldData;
cStackFixEndFn:  Stacks.data[ptr].endfn  := fieldData;
cStackFixNameId: Stacks.data[ptr].namep  := fieldData;
cStackFixLineNo: Stacks.data[ptr].lineno := fieldData;
    else
      writeln('illegal field selected for StackFix datatype');
      halt(1);
    end;
  end;

  function getStackFixField( ptr : integer; field : tStackFixField ): integer;
  var
    fieldData : integer;
  begin
    fieldData := -1;
    case field of
cStackFixId:     fieldData := Stacks.data[ptr].id;
cStackFixHint:   fieldData := Stacks.data[ptr].hint;
cStackFixEvents: fieldData := Stacks.data[ptr].events;
cStackFixStart:  fieldData := Stacks.data[ptr].start;
cStackFixTrap:   fieldData := Stacks.data[ptr].trap;
cStackFixEvFrom: fieldData := Stacks.data[ptr].evfrom;
cStackFixEndFn:  fieldData := Stacks.data[ptr].endfn;
cStackFixNameId: fieldData := Stacks.data[ptr].namep;
cStackFixLineNo: fieldData := Stacks.data[ptr].lineno;
    else
      writeln('illegal field selected for StackFix datatype');
      halt(1);
    end;
    getStackFixField := fieldData;
  end;

  function findStackFixById( fixupId : integer ):integer;
  var
    ptr : integer;
    i : integer;
  begin
    ptr := -1;
    i := 1;
    while (i <= Stacks.count) and (ptr = -1) do
    begin
      if (Stacks.data[i].id = fixupId) then
      begin
        ptr := i;
      end
      else
      begin
        i := i + 1;
      end;
    end;
    findStackFixById := ptr;
  end;

end.
