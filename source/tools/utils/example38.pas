{ This program demonstrates the FileExists function }
program Example38;
uses
  sysutils;

begin
  if FileExists( ParamStr(0) ) then
    Writeln ('All is well, I seem to exist.');
end.