{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit sectdef;
interface

const
  // Internal coff sections, according to the file writer
  cDIRECTIVESECTION = 1;
  cCODESECTION      = 2;
  cCONSTSECTION     = 3;
  cDATASECTION      = 4;
  cSWTABSECTION     = 5;
  cTRAPSECTION      = 6;
  cTRAPENDSECTION   = 7;
  // and three pseudo sections for our file write that correspond to the
  // three parts of the relocation table (code, switch table, and trap table)
  cCODERELSECTION   = 8;
  cSWTABRELSECTION  = 9;
  cTRAPRELSECTION   = 10;
  // then the pseudo section that is the line number table
  cLINENOSECTION    = 11;

  function sectIdToName( section : integer ): string;
  
implementation

  function sectIdToName( section : integer ): string;
  var
    name : string;
  begin
    case section of
-1:                name := 'FREETOUSE';
cDIRECTIVESECTION: name := 'DIRECTIVESECTION';
cCODESECTION:      name := 'CODESECTION';
cCONSTSECTION:     name := 'CONSTSECTION';
cDATASECTION:      name := 'DATASECTION';
cSWTABSECTION:     name := 'SWTABSECTION';
cTRAPSECTION:      name := 'TRAPSECTION';
cTRAPENDSECTION:   name := 'TRAPENDSECTION';
// and three pseudo sections for our file write that correspond to the
// three parts of the relocation table (code, switch table, and trap table)
cCODERELSECTION:   name := 'CODERELSECTION';
cSWTABRELSECTION:  name := 'SWTABRELSECTION';
cTRAPRELSECTION:   name := 'TRAPRELSECTION';
// then the pseudo section that is the line number table
cLINENOSECTION:    name := 'LINENOSECTION';
    else
      name := 'ILLEGAL'
    end;

    sectIdToName := name;
  end;

end.
