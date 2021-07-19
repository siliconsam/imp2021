{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
program icd2dump(input,output);
uses
  sysutils,
  dos,
  icdio;

  procedure DumpICDFile( infilename,outfilename : string );
  var
    fin : ficode;
    fout : text;
    lineNo : integer;
    ibyte : uinteger8;
    iCode : char;

    s : string;
  begin
    assign( fin, InFileName );
    reset( fin );
    lineno := 0;
  
    assign( fout, OutFileName );
    rewrite( fout );
    
    lineNo := 0;
    s := '';
    (* Now to read the IBJ file until the end of file *)
    while not eof(fin) do
    begin
      (* read the current line and update the count of lines read so far *)
      read(fin, iByte );
      iCode := chr( iByte );
      lineNo := lineNo + 1;

      if (ord(iCode) = 0) then
      begin
        s := s + '<*NUL*>';
      end
      else if (ord(iCode) = 1) then
      begin
        s := s + '<*SOH*>';
      end
      else if (ord(iCode) = 2) then
      begin
        s := s + '<*STX*>';
      end
      else if (ord(iCode) = 3) then
      begin
        s := s + '<*ETX*>';
      end
      else if (ord(iCode) = 4) then
      begin
        s := s + '<*EOT*>';
      end
      else if (ord(iCode) = 5) then
      begin
        s := s + '<*ENQ*>';
      end
      else if (ord(iCode) = 6) then
      begin
        s := s + '<*ACK*>';
      end
      else if (ord(iCode) = 7) then
      begin
        s := s + '<*BEL*>';
      end
      else if (ord(iCode) = 8) then
      begin
        s := s + '<*BS*>';
      end
      else if (ord(iCode) = 9) then
      begin
        s := s + '<*HT*>';
      end
      else if (ord(iCode) = 10) then
      begin
        s := s + '<*LF*>';
      end
      else if (ord(iCode) = 11) then
      begin
        s := s + '<*VT*>';
      end
      else if (ord(iCode) = 12) then
      begin
        s := s + '<*FF*>';
      end
      else if (ord(iCode) = 13) then
      begin
        s := s + '<*CR*>';
      end
      else if (ord(iCode) = 14) then
      begin
        s := s + '<*SO*>';
      end
      else if (ord(iCode) = 15) then
      begin
        s := s + '<*SI*>';
      end
      else if (ord(iCode) = 16) then
      begin
        s := s + '<*DLE*>';
      end
      else if (ord(iCode) = 17) then
      begin
        s := s + '<*DC1*>';
      end
      else if (ord(iCode) = 18) then
      begin
        s := s + '<*DC2*>';
      end
      else if (ord(iCode) = 19) then
      begin
        s := s + '<*DC3*>';
      end
      else if (ord(iCode) = 20) then
      begin
        s := s + '<*DC4*>';
      end
      else if (ord(iCode) = 21) then
      begin
        s := s + '<*NAK*>';
      end
      else if (ord(iCode) = 22) then
      begin
        s := s + '<*SYN*>';
      end
      else if (ord(iCode) = 23) then
      begin
        s := s + '<*ETB*>';
      end
      else if (ord(iCode) = 24) then
      begin
        s := s + '<*CAN*>';
      end
      else if (ord(iCode) = 25) then
      begin
        s := s + '<*EM*>';
      end
      else if (ord(iCode) = 26) then
      begin
        s := s + '<*SUB*>';
      end
      else if (ord(iCode) = 27) then
      begin
        s := s + '<*ESC*>';
      end
      else if (ord(iCode) = 28) then
      begin
        s := s + '<*FS*>';
      end
      else if (ord(iCode) = 29) then
      begin
        s := s + '<*GS*>';
      end
      else if (ord(iCode) = 30) then
      begin
        s := s + '<*RS*>';
      end
      else if (ord(iCode) = 31) then
      begin
        s := s + '<*US*>';
      end
      else if (ord(iCode) = 32) then
      begin
        s := s + '<*SP*>';
      end
      else if (ord(iCode) < 33) or (127 < ord(iCode)) then
      begin
        s := s + '<*' + IntToHex(ord(iCode),3) + '*>';
      end
      else
      begin
        s := s + iCode;
      end;
      if (length(s) > 64) then
      begin
        writeln(fout,s);
        s := '';
      end;
    end;
    if (length(s) > 0) then
    begin
      writeln(fout,s);
      s := '';
    end;
    close(fin);
    close(fout);
  end;

begin
  if (ParamCount = 2) then
  begin
    DumpICDFile( ParamStr( 1 ), ParamStr( 2 ) );
  end
  else
  begin
    writeln('icd2dump: 2 parameters expected: icd2dump [icode file] [text dump file]');
  end;
end.