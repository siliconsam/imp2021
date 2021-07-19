{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program ibj2assemble(input,output);
uses
  dos,
  sysutils,
  ibjdef,
  ibjutil,
  nameutil,
  specutil,
  parseutil;

  procedure initialise;
  begin
    initialiseNames();
    initialiseSpecs();
  end;

  procedure help();
  begin
    writeln('IBJ2ASSEMBLE: 2 parameters expected: ibj2assemble [ibj file] [ibj assembler file]');
  end;

begin
  if (ParamCount = 2) then
  begin
    if fileExists( ParamStr( 1 ) ) then
    begin
      initialise();
      if not parseIBJFile( ParamStr( 1 ), ParamStr( 2 ), cPassAssemble, -1, false ) then
      begin
        writeln( ' **** ERRORS detected in the input IBJ file ',ParamStr(1) );
      end;
    end
    else
    begin
      writeln( 'IBJ Input File ',ParamStr(1),' does not exist!' );
      writeln(' So program aborted' );
      writeln();
      help();
    end;
  end
  else
  begin
    help();
  end;
end.
