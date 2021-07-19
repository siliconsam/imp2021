{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program ibj2compact(input,output);
uses
  dos,
  sysutils,
  ibjdef,
  ibjutil,
  nameutil,
  specutil,
  parseutil;

const
  Version = '1.0';

  procedure help();
  begin
    writeln('IBJ2COMPACT: Version ',version);
    writeln('IBJ2COMPACT: 2 parameters expected: ibj2compact [ibj file] [new compacted ibj file]');
  end;

begin
  if (ParamCount = 2) then
  begin
    if fileExists( ParamStr( 1 ) ) then
    begin
      initialiseNames();
      initialiseSpecs();
      if parseIBJFile( ParamStr( 1 ), '', cPassCompactRead, -1, false ) then
      begin
        (* Input IBJ file has no errors *)
        (* So, we can renumber the used REQEXT symbols *)
        renumberNames();
        (* re-read, modify and output the new compacted IBJ file *) 
        parseIBJFile( ParamStr( 1 ), ParamStr( 2 ), cPassCompactWrite, -1, false );
      end
      else
      begin
        writeln( ' IBJ Input File ',ParamStr(1),' has errors' );
      end;
    end
    else
    begin
      writeln( ' Input File ',ParamStr(1),' does not exist!' );
      writeln( ' So program aborted' );
      writeln();
      help();
    end;
  end
  else
  begin
   help();
  end;
end.
