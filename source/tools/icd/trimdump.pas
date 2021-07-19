program trimDump(input,output);
uses
  sysutils,
  dos;
type
  ficode = file of byte;

  function GetProgramPath : string;
  var
    d,n,e : string;
  begin
    FSplit(ParamStr(0),d,n,e);
    GetProgramPath := d;
  end;

  procedure trimFile( infilename, outfilename : string );
  var
    fin : text;
    fout : text;
    data : string;
  begin
    assign( fin, infilename );
    reset( fin );

    assign( fout, outfilename );
    rewrite( fout );
    
    (* Now to read the IBJ file until the end of file *)
    while not eof(fin) do
    begin
      (* read the current line and update the count of lines read so far *)
      readln(fin, data );
      if (length(data) > 8) then
      begin
        writeln(fout,copy(data, 9, length(data) - 8 ));
      end
      else
      begin
        writeln(fout,data);
      end;
    end;
    close(fin);
    close(fout);
  end;

begin
  if (ParamCount = 2) then
  begin
    trimFile( ParamStr( 1 ), ParamStr( 2 ) );
  end
  else
  begin
    writeln('TRIMDUMP: 2 parameters expected: trimdump [numberedfile] [assemblerfile]');
  end;
end.