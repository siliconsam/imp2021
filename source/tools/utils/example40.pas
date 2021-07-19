{ This program demonstrates the FileGetAttr function }
program Example40;
uses sysutils;

  procedure Testit (Name : String);
  var F : Longint;
  begin
    F:=FileGetAttr(Name);
    if F<>-1 then
    begin
      Writeln ('Testing : ',Name);
      If (F and faReadOnly)<>0  then Writeln ('File is ReadOnly');
      If (F and faHidden)<>0    then Writeln ('File is hidden');
      If (F and faSysFile)<>0   then Writeln ('File is a system file');
      If (F and faVolumeID)<>0  then Writeln ('File is a disk label');
      If (F and faArchive)<>0   then Writeln ('File is artchive file');
      If (F and faDirectory)<>0 then Writeln ('File is a directory');
    end
    else
     Writeln ('Error reading attributes of ',Name);
  end;

begin
  testit ('ex40.pas');
  testit (ParamStr(0));
  testit ('.');
  testit ('/');
end.