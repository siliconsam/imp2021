{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit specutil;
interface

  procedure initialiseSpecs();
  function checkValidSpecId( specId : integer ): boolean;
  function getSpecCount(): integer;
  function getSpecTotal(): integer;
  procedure setSpecTotal( newtotal : integer );
  function newSpec( nameId : integer ): integer;
  function getSpecNameId( specIndex : integer ): integer;
  procedure setSpecNameId( specIndex : integer; newNameId : integer );
  function getSpecUsed( specIndex : integer ): boolean;
  procedure setSpecUsed( specIndex : integer );
  function getSpecP3Index( specIndex : integer ): integer;
  procedure setSpecP3Index( specIndex : integer; newP3Index : integer );
  procedure setSpecIsdata( specIndex : integer );
  function getSpecIsdata( specIndex : integer ): boolean;
  function findSpecIndexByNameId( nameId : integer ): integer;
  function findSpecIndexByP3Index( p3Index : integer ): integer;
  procedure remapspecs();

implementation

const
  MaxSpec = 250;

type
  tSpec =
  record
    nameId  : integer;
    p3index : integer;
    used    : boolean;
    isdata  : boolean;
  end;

  tSpecArray =
  record
    count : 0..MaxSpec;
    total : 0..MaxSpec;
    data  : array [0..MaxSpec] of tSpec;
  end;

var
  Specs : tSpecArray;

  procedure initialiseSpecs();
  begin
    specs.count := 0;
    specs.total := 0;
  end;

  function checkValidSpecId( specId : integer ): boolean;
  begin
    checkValidSpecId := (0 <= specId) and (specId <= specs.count);
  end;

  function getSpecCount(): integer;
  begin
    getSpecCount := specs.count;
  end;

  function getSpecTotal(): integer;
  begin
    getSpecTotal := specs.total;
  end;

  procedure setSpecTotal( newtotal : integer );
  begin
    specs.total := newtotal;
  end;

  function newSpec( nameId : integer ): integer;
  var
    specId : integer;
  begin
//    specId := -1;
    // check to see if a spec for this name already exists
    specId := findSpecIndexByNameId( nameId );
    if (specId = -1) then
    begin
      if (specs.count < MaxSpec) then
      begin
        specs.count := specs.count + 1;

        specs.data[specs.count].nameId  := nameId;
        specs.data[specs.count].p3index := -1;
        specs.data[specs.count].used    := false;
        specs.data[specs.count].isdata  := false;

        specId := specs.count;
      end
      else
      begin
        (* report overflow for implementation *)
        writeln('**** FATAL **** Too many Specs for this implementation');
        writeln('**** INFO  **** Increase MaxName (currently ',MaxSpec,')');
      end;
    end
    else
    begin
      // this spec already exists, so return the existing spec id
      // this avoids duplicated specs
    end;

    newSpec := specId;
  end;

  function getSpecNameId( specIndex : integer ): integer;
  begin
    getSpecNameId := specs.data[specIndex].nameId;
  end;

  procedure setSpecNameId( specIndex : integer; newNameId : integer );
  begin
    specs.data[specIndex].nameId := newNameId;
  end;

  function getSpecUsed( specIndex : integer ): boolean;
  begin
    getSpecUsed := specs.data[specIndex].used;
  end;

  procedure setSpecUsed( specIndex : integer );
  begin
    specs.data[specIndex].used := true;
  end;

  function getSpecP3Index( specIndex : integer ): integer;
  begin
    getSpecP3Index := specs.data[specIndex].p3index;
  end;

  procedure setSpecP3Index( specIndex : integer; newP3Index : integer );
  begin
    specs.data[specIndex].p3index := newP3Index;
  end;

  procedure setSpecIsdata( specIndex : integer );
  begin
    specs.data[specIndex].isdata := true;
  end;

  function getSpecIsdata( specIndex : integer ): boolean;
  begin
    getSpecIsdata := specs.data[specIndex].isdata;
  end;

  function findSpecIndexByNameId( nameId : integer ): integer;
  var
    i, specIndex : integer;
  begin
    specIndex := -1;
    i := 1;
    while (i <= Specs.count) and (specIndex = -1) do
    begin
      if (Specs.data[i].nameId = nameId) then
      begin
        specIndex := i;
      end
      else
      begin
        i := i + 1;
      end;
    end;
    findSpecIndexByNameId := specIndex;
  end;

  function findSpecIndexByP3Index( p3Index : integer ): integer;
  var
    i, specIndex : integer;
  begin
    specIndex := -1;
    i := 1;
    while (i <= Specs.count) and (specIndex = -1) do
    begin
      if (Specs.data[i].p3Index = p3Index) then
      begin
        specIndex := i;
      end
      else
      begin
        i := i + 1;
      end;
    end;
    findSpecIndexByP3Index := specIndex;
  end;

  // run through the list of external specs, removing those that
  // have not actually been used, and mapping the indexes of those
  // that remain to a simple zero-based index
  procedure remapspecs();
  var
	i, p3 : integer;
  begin
    p3 := 0; // note, although Pass2 references are 1-based, our map is 0-based
    for i := 1 to getSpecCount() do
    begin
      if getSpecUsed(i) then
      begin
        setSpecP3Index( i, p3 );
        p3 := p3 + 1;
      end;
    end;
    // reassign the specs counter so we know how many we will plant
    setSpecTotal( p3 );
  end;

end.
