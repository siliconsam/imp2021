{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit labelUtil;
interface
uses
  dos,
  sysutils;

  procedure initialiseLabels();
  function getLabelCount(): integer;
  function newlabel(): integer;
  function getLabelId( i : integer): integer;
  procedure setLabelId( i : integer; newId : integer );
  function getLabelAddress( i : integer): integer;
  procedure setLabelAddress( i : integer; newAddress : integer );
  function findLabel( id : integer ): integer;

implementation
const
  MaxLabel = 2500;

type
  tLabel =
  record
    labelid : integer;
    address : integer;
  end;

  tLabelArray =
  record
    count : 0..MaxLabel;
    data  : array [0..MaxLabel] of tLabel;
  end;

var
  Labels : tLabelArray;

  procedure initialiseLabels();
  begin
    Labels.count := 0;
  end;

  function getLabelCount(): integer;
  begin
    getLabelCount := Labels.count;
  end;

  (* return the index of the next item block *)
  function newlabel(): integer;
  var
    newId : integer;
  begin
    newid := -1;
    if (Labels.count = MaxLabel) then
    begin
      writeln( 'Program/module too big' );
      writeln( 'Increase the value of MaxLabels. (currently (',MaxLabel,')' );
    end
    else
    begin
      Labels.count := Labels.count + 1;
      newId := Labels.Count;
    end;
    newLabel := newId;
  end;

  function getLabelId( i : integer): integer;
  begin
    getLabelId := Labels.data[i].labelId;
  end;

  procedure setLabelId( i : integer; newId : integer );
  begin
    Labels.data[i].labelId := newId;
  end;

  function getLabelAddress( i : integer): integer;
  begin
    getLabelAddress := Labels.data[i].address;
  end;

  procedure setLabelAddress( i : integer; newAddress : integer );
  begin
    Labels.data[i].address := newAddress;
  end;

  function findLabel( id : integer ): integer;
  var
    count, i,j : integer;
  begin
    count := getLabelCount();
    j := 0;
    for i := 1 to count do
    begin
      // find first instance of label id
      if (getLabelId(i) = id) and (j = 0) then j := i;
    end;
    findLabel := j;
  end;

end.
