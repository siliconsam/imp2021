program Example33;

  { This program demonstrates the ExpandFileName function }

uses
  sysutils;

  procedure Testit (F : String);
  var
    fullname,
    filepath,
    filename,
    barename,
    fileext,
    sourcefile : string;
  begin
    fullname := ExpandFileName(f);
    filepath := ExtractFilePath(fullname);
    filename := ExtractFileName(fullname);
    fileext := ExtractFileExt(fullname);
    barename := copy(filename,1,pos(fileext,filename)-1);
    sourcefile := filepath+barename+'.imp';
    writeln('<',F,'> expands to : ',fullName);
    if (fullname[length(fullname)] = '\') or (f = '.') or (f = '..') then
      writeln('<',f,'> is a directory')
    else
      writeln('<',f,'> is a file');

    writeln('    Drive : ',ExtractFileDrive(fullname));
    writeln('     Path : ',filepath);
    writeln(' Filename : ',filename);
    writeln('      Ext : ',fileext);
    writeln('     File : ',barename);
    writeln('   Source : ',sourcefile);
    writeln();
  end;

begin
  Testit('ex33.pp');
  Testit(ParamStr(0));
//  Testit('/pp/bin/win32/ppc386');
//  Testit('\pp\bin\win32\ppc386');
  Testit('');
  Testit('.');
  Testit('..\..\assembler');
end.
