{ This program demonstrates the FindFirst function }
program Example43;
uses
  SysUtils;

var
  Info : TSearchRec;
  Count : Longint;

begin
  Count:=0;
  if FindFirst ('*',faAnyFile,Info)=0 then
  begin
    repeat
      Inc(Count);
      with Info do
      begin
        if (Attr and faDirectory) = faDirectory then Write('Dir : ');
        Writeln (Name:40,Size:15);
      end;
    until FindNext(info)<>0;
    FindClose(Info);
  end;
  Writeln ('Finished search. Found ',Count,' matches');
end.

