{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit lineUtil;
interface
uses
  dos,
  sysutils;

  procedure initialiseLines();
  function getLineCount(): integer;
  function getLastLineAddress(): integer;
  procedure newlineno( line : integer; addr : integer );
  function getLineOffset( lineIndex : integer ): integer;
  function getLineNo( lineIndex : integer ): integer;

implementation
const
  MaxLineNo      = 4000;

type
  tLineNo =
  record
	line   : integer;
	offset : integer;
  end;

  tLineNoArray =
  record
    count : 0..MaxLineNo;
    lastLineAddress : integer;
    data  : array [0..MaxLineNo] of tLineNo;
  end;

var
  LineNo : tLineNoArray;

  procedure initialiseLines();
  begin
    LineNo.lastLineAddress := -1;
    LineNo.count := 0;
  end;

  function getLineCount(): integer;
  begin
    getLineCount := LineNo.count;
  end;

  function getLastLineAddress(): integer;
  begin
    getLastLineAddress := LineNo.lastLineAddress;
  end;

  (* report this line number as being at this address *)
  procedure newlineno( line : integer; addr : integer );
  begin
    (* is this line the same address as we already have? *)
    if (addr = LineNo.lastLineAddress)	then (* lines have advanced, but code didn't *)
    begin
      LineNo.data[LineNo.count-1].line := line; (* update current record *)
    end
    else
    begin
      if (LineNo.count < MaxLineNo) then (* only if there is room *)
      begin
        LineNo.data[LineNo.count].line := line;
        LineNo.data[LineNo.count].offset := addr;
        LineNo.count := LineNo.count + 1;
        LineNo.lastLineAddress := addr;
      end;
	end;
  end;

  function getLineOffset( lineIndex : integer ): integer;
  begin
    getLineOffset := LineNo.data[lineIndex].offset;
  end;

  function getLineNo( lineIndex : integer ): integer;
  begin
    getLineNo := LineNo.data[lineIndex].line;
  end;

end.
