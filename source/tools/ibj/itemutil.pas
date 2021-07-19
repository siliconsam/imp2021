{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit itemUtil;
interface
uses
  dos,
  sysutils,
  ibjdef;

type
  tItemField = (cItemId
               ,cItemType
               ,cItemIBJType
               ,cItemSize
               ,cItemInfo
               ,cItemAddress
               ,cItemLineNo
               );

  procedure initialiseItems();
  function getItemCount(): integer;
  function newItem( whatType, realtype : integer ): integer;
  function getItemField( ptr : integer; field : tItemField ): integer;
  procedure setItemField( ptr : integer; field : tItemField; fieldData : integer);

implementation
const
  MaxItem = 10000;

type
  tItem =
  record
    id      : integer; // id of this item
    what    : integer; // what this block describes
    ibjwhat : integer; // ibj type
    size    : integer; // size this block occupies in the image (generally in bytes)
    info    : integer; // type dependent extra information
    address : integer; // the address in the image

    lineno  : integer; // line number in IBJ file generating record
  end;

  tItemArray =
  record
    count : 0..MaxItem;
    data  : array [1..MaxItem] of tItem;
  end;

var
  Items : tItemArray;

  procedure initialiseItems();
  begin
    Items.count := 0;
  end;

  function getItemCount(): integer;
  begin
    getItemCount := Items.count;
  end;

  function newItem( whatType, realType : integer ): integer;
  begin
    if (Items.count = MaxItem) then
    begin
      writeln( 'Program/module too big' );
      writeln( 'Increase the value of MaxItem' );
      exit(1);
    end;

    Items.count := Items.count + 1;
    Items.data[Items.count].id      := Items.count;
    Items.data[Items.count].what    := whattype;
    Items.data[Items.count].ibjwhat := realtype;
    Items.data[Items.count].size    := 0;
    Items.data[Items.count].info    := 0;
    Items.data[Items.count].address := 0;
    Items.data[Items.count].lineno  := 0;
    newItem := Items.data[Items.count].id;
  end;

  function getItemField( ptr : integer; field : tItemField ): integer;
  var
    fieldData : integer;
  begin
    fieldData := -1;
    if (0 < ptr) and (ptr <= Items.count) then
    begin
      case field of
cItemId:      fieldData := Items.data[ptr].id;
cItemType:    fieldData := Items.data[ptr].what;
cItemIBJType: fieldData := Items.data[ptr].ibjwhat;
cItemSize:    fieldData := Items.data[ptr].size;
cItemInfo:    fieldData := Items.data[ptr].info;
cItemAddress: fieldData := Items.data[ptr].address;
cItemLineNo:  fieldData := Items.data[ptr].lineno;
      else
      end;
    end;
    getItemField := fieldData;
  end;

  procedure setItemField( ptr : integer; field : tItemField; fieldData : integer);
  begin
    if (0 < ptr) and (ptr <= Items.count) then
    begin
      case field of
cItemId:      Items.data[ptr].id      := fieldData;
cItemType:    Items.data[ptr].what    := fieldData;
cItemIBJType: Items.data[ptr].ibjwhat := fieldData;
cItemSize:    Items.data[ptr].size    := fieldData;
cItemInfo:    Items.data[ptr].info    := fieldData;
cItemAddress: Items.data[ptr].address := fieldData;
cItemLineNo:  Items.data[ptr].lineno  := fieldData;
      else
      end;
    end;
  end;

end.
