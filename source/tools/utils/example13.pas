{ This program demonstrates the FileDateToDateTime function }
program Example13;
uses
  sysutils;

var
  ThisAge : Longint;

begin
 Write ('ex13.pas created on :');
 ThisAge := FileAge('ex13.pas');
 Writeln( DateTimeToStr( FileDateToDateTime( ThisAge ) ) );
end.