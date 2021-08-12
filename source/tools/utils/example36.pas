{ This program demonstrates the FileAge function }
program Example36;
uses
  sysutils;

var
  S : TDateTime;
  fa : Longint;

begin
  fa:=FileAge('ex36.pas');
  if Fa<>-1 then
  begin
    S:=FileDateTodateTime(fa);
    Writeln ('I''m from ',DateTimeToStr(S))
  end;
end.