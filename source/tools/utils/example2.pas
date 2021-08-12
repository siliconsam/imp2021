{ This program demonstrates the DateTimeToFileDate function }
program Example2;
uses
  sysutils;

begin
  Writeln('FileTime of now would be: ', DateTimeToFileDate( Now ) );
end.