{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit nameUtil;
interface
uses
  dos,
  sysutils;

  procedure initialiseNames();
  function getNameCount(): integer;
  function newName( name : string ): integer;
  procedure setNameUsed( nameIndex : integer );
  function getNameUsed( nameIndex : integer ): boolean;
  function getNameId( nameIndex : integer ): integer;
  function getNameDict( nameIndex : integer ): integer;
  function getNameString( nameIndex : integer ): string;
  function findNameIndexByString( n : string ): integer;
  procedure renumberNames();
  procedure addNameToDictionary( nameIndex : integer );
  procedure formDictionary();
  procedure writeDictionary( fout : longint );
  function getDictionarySize(): integer;
  function getNameDictionaryIndex( nameIndex : integer ): integer;

implementation
const
  MaxName        = 1000;
  MaxDictionary  = 50000;

type
  tName =
  record
    name      : string;  // name
    used      : boolean; // referenced 
    id        : integer; // symbol id (only valid after compacting)
    dict      : integer; // dictionary table index
  end;

  tNameArray =
  record
    count      : 0..MaxName;
    dictSize   : integer;
    data       : array [0..MaxName] of tName;
    dictionary : array [0..MaxDictionary] of byte;
  end;

var
  Names : tNameArray;

  procedure initialiseNames();
  begin
    Names.count := 0;
    Names.data[0].used := false;
    
    Names.dictSize := 4; // 2 bytes for dictionary size word + 2 bytes for zero'th name
  end;

  function getNameCount(): integer;
  begin
    getNameCount := Names.count;
  end;

  function newName( name : string ): integer;
  var
    nameIndex : integer;
  begin
    nameIndex := findNameIndexByString( name );
    if (nameIndex = -1) then
    begin
      (* only if there is room *)
      if (names.count >= MaxName) then
      begin
        (* No room at the inn!! *)
        (* report overflow for implementation *)
        writeln('**** FATAL **** Too many names for this implementation');
        if (Names.count >= MaxName) then
        begin
          writeln('**** INFO  **** Increase MaxName (currently ',MaxName,')');
        end;

        nameIndex := -1;
      end
      else
      begin
        Names.count := Names.count + 1;
        Names.data[Names.count].name := name;
        Names.data[Names.count].used := false;
        Names.data[Names.count].id   := Names.count;
        Names.data[Names.count].dict := 0;
        nameIndex := Names.count;
      end;
    end;

    newName := nameIndex;
  end;

  procedure setNameUsed( nameIndex : integer );
  begin
    if (1 <= nameIndex) and (nameIndex <= Names.count) then (* only if present *)
    begin
      Names.data[nameIndex].used := true;
    end;
  end;

  function getNameUsed( nameIndex : integer ): boolean;
  begin
    getNameUsed := Names.data[nameIndex].used;
  end;

  function getNameId( nameIndex : integer ): integer;
  begin
    getNameId := Names.data[nameIndex].id;
  end;

  function getNameDict( nameIndex : integer ): integer;
  begin
    getNameDict := Names.data[nameIndex].dict;
  end;

  function getNameString( nameIndex : integer ): string;
  var
    s : string;
  begin
    (* form default name *)
    s := '';
    if (1 <= nameIndex) and (nameIndex <= Names.count) then
    begin
      s := Names.data[nameIndex].name;
    end;
    getNameString := s;
  end;

  function findNameIndexByString( n : string ): integer;
  var
    i, nameIndex : integer;
  begin
    nameIndex := -1;
    i := 1;
    while (i <= Names.count) and (nameIndex = -1) do
    begin
      if (Names.data[i].name = n) then
      begin
        nameIndex := i;
      end
      else
      begin
        i := i + 1;
      end;
    end;
    findNameIndexByString := nameIndex;
  end;

  procedure renumberNames();
  var
    i, newid : integer;
  begin
    newid := 0;
    for i := 1 to Names.count do
    begin
      if Names.data[i].used then
      begin
        newid := newid + 1;
        Names.data[i].id := newid;
      end
      else
      begin
        Names.data[i].id := -1;
      end;
    end;
  end;

  procedure addNameToDictionary( nameIndex : integer );
  var
    j   : integer;
    len : integer;
  begin
    // jam Name into dictionary
    len := length(Names.data[nameIndex].name);
    if ((len + names.dictSize) < MaxDictionary) then
    begin
      // note the name's dictionary index
      Names.data[nameIndex].dict := Names.dictsize;
      // add the name text to the dictionaty text
      for j := 1 to len do
      begin
        Names.dictionary[Names.dictsize + j - 1] := ord(Names.data[nameIndex].name[j]);
      end;
      // don't forget the string terminator
      Names.dictionary[Names.dictSize + len] := 0;
      // remember the dictionary size == next free space in dictionary
      Names.dictsize := Names.dictsize + len + 1;
    end
    else
    begin
      // drat, not enough space
      // set the dict value for this name to point to symbol 0
      Names.data[nameIndex].dict := 2;

      // now report overflow for implementation
      writeln('**** FATAL **** String table overflow for this implementation');
      writeln('**** INFO  **** Increase MaxDictionary from ',MaxDictionary,' to at least ',(len + Names.dictsize));
    end;
    // Don't forget to remember the dictionary size (inside the dictionary)
    Names.dictionary[0] := (Names.dictSize shr 0) and $ff;
    Names.dictionary[1] := (Names.dictSize shr 8) and $ff;
  end;

  procedure formDictionary();
  var
    i : integer;
  begin
    // leave space for dictionary size (=dictsize) and empty symbol 0
    Names.dictsize := 4;

    // Go over the names and only add used symbols
    for i := 1 to Names.count do
    begin
      if Names.data[i].used then
      begin
        addNameToDictionary( i );
      end;
    end;
  end;

  procedure writeDictionary( fout : longint );
  var
    i : integer;
  begin
    for i := 0 to Names.dictSize - 1 do
    begin
      FileWrite( fout, Names.dictionary[i], 1);
    end;
  end;

  function getDictionarySize(): integer;
  begin
    getDictionarySize := Names.dictsize;
  end;

  function getNameDictionaryIndex( nameIndex : integer ): integer;
  begin
    getNameDictionaryIndex := Names.data[nameIndex].dict;
  end;

end.
