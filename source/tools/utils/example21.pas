Program Example21;

{ Program to demonstrate the log10 function. }

Uses math,sysutils;

  function doubleToIcodeMantissa( d : double ): string;
  var
    m : float;
  begin
    m := frac(log10(d));

    if (m < 0.0) then
    begin
      m := m + 1.0;
    end;

    doubleToIcodeMantissa := FloatToStr( power( 10.0, m ) );
  end;

  function doubleToIcodeExponent( d : double ): integer;
  var
    m : float;
    e : integer;
  begin
    m := frac(log10(d));
    e := trunc(log10(d));

    if (m < 0.0) then
    begin
      e := e - 1;
    end;

    doubleToIcodeExponent := e;
  end;

  function doubleToImpFloat( d : double ):string;
  var
    e : integer;
    is : string;
  begin
    is := doubleToIcodeMantissa( d );
    e := doubleToIcodeExponent( d );
    if (e <> 0) then
    begin
      is := is + '@' + IntToStr( e );
    end;

    doubleToImpFloat := is;
  end;

  function impFloatToDouble( rs : string ): double;
  var
    ints : string;
    decs : string;
    exps : string;
    dotloc : integer;
    atloc : integer;
    noErrorFlag : boolean;
    
    inti : int64;
    expi : int64;
    d : double;
  begin
    { ints is string before decimal point == integer part }
    { decs is string after decimal point and before @ == fractional part }
    { exps is string after @ == exponent }
    noErrorFlag := true; { ass-u-me no errors! }
    d := 0.0; { give a default value - in case of any errors }

    { Let's start by finding the decimal point and @ locations }
    { if pos give 0 result then required sub-string is NOT present }
    dotloc := pos('.',rs);
    atloc := pos('@',rs);

    { Check for a decimal point }
    case (dotLoc > 0) of
false:
      begin
        { No decimal point found }
        { Next, check for an @ }
        case (atloc > 0) of
  false:
          begin
            { no @ for exponent found }
            { so, rs is of form nnn i.e. a pure integer }
            ints := rs;
            decs := '';
            exps := '';
          end;
   true:
          begin
            { @ for exponent found }
            { so, rs has form nnn@nn, again a pure integer }
            ints := copy(rs,1,atloc - 1);
            decs := '';
            exps := copy(rs,atloc + 1,length(rs) - atloc);
          end;
        end;
      end;
true:
      begin
        { decimal point found }
        { Next, check for an @ }
        case (atloc > 0) of
  false:
          begin
            { no @ for exponent found }
            { so, rs of form nnn.nn }
            ints := copy(rs,1,dotloc - 1);
            decs := copy(rs,dotloc + 1, length(rs) - atloc);
            exps := '';
          end;
   true:
          begin
            { @ for exponent found }
            { BUT, are the decimal point and @ in the correct order }
            { Expect decimal point BEFORE @ }
            if (dotLoc < atLoc) then
            begin
              ints := copy(rs,1,dotloc - 1);
              decs := copy(rs,dotloc + 1, atloc - (dotloc + 1));
              exps := copy(rs,atloc + 1,length(rs) - atloc);
            end
            else
            begin
              { drat error, the @ is before the decimal point }
              noErrorFlag := false;
            end;
          end;
        end;
      end;
    end;

{
    writeln();
    writeln('IMP float = <',rs,'> ints = <',ints,'> decs = <',decs,'> exps = <',exps,'>' );
}

    if noErrorFlag then
    begin
      { Ok, we have 3 strings (possible 1,2 being empty) }
      { representing integer part, decimal part and exponent part }
      { Convert exponent string to an integer }
      if (exps <> '') then expi := StrToInt(exps) else expi := 0;
      { We will now form a large integer by concatenating ints and decs }
      { but we need to tweak the exponent by the length of decs }
      expi := expi - length(decs);
      inti := StrToInt(ints+decs);
      
      { ok, we have converted rs into ordered pair (inti,expi) }
      { But we want a double }
      { So we need to first form a double from inti }
      d := inti;
      { Now to incorporate the value of the exponent, expi }
      if (expi <> 0) then
      begin
        { ok, non-zero exponent }
        if (expi > 0) then
        begin
          { positive exponent }
          while (expi > 0) do
          begin
            expi := expi - 1;
            d := d * 10;
          end;
        end
        else
        begin
          { negative exponent }
          expi := -expi;
          while (expi > 0) do
          begin
            expi := expi - 1;
            d := d / 10;
          end;
        end;
      end;
    end;

    impFloatToDouble := d;
  end;
  
  procedure doCalc( d : double );
  var
    f : float;
    l : float;
    m : float;
    e : integer;
  begin
    f := d;

    l := log10(f);

    m := frac(l);
    e := trunc(l);

    if (m < 0.0) then
    begin
      l := l - 1.0;
      m := m + 1.0;
      e := e - 1;
    end;

    if (e <> 0) then
    begin
      Writeln('d=',d:9:4,' => float=',power( 10.0, m ) * power( 10.0, e ):9:4,' IMP77 version ',FloatToStr( power( 10.0, m ) ),'@',e);
    end
    else
    begin
      Writeln('d=',d:9:4,' => float=',power( 10.0, m ) * power( 10.0, e ):9:4,' IMP77 version ',FloatToStr( power( 10.0, m ) ));
    end;
  end;

  procedure fudge( s : string );
  var
    d : double;
    
    m : string;
    e : integer;
  begin
    d := impFloatToDouble( s );
    
    m := doubleToIcodeMantissa( d );
    e := doubleToIcodeExponent( d );

    writeln( 'Input=<',s,'> mantissa=<',m,'> exponent=<',e,'>');
  end;

begin

{
  doCalc(   10     );   doCalc( impFloatToDouble( doubleToImpFloat(   10     ) ) ); writeln();
  doCalc(  100     );   doCalc( impFloatToDouble( doubleToImpFloat(  100     ) ) ); writeln();
  doCalc( 1000     );   doCalc( impFloatToDouble( doubleToImpFloat( 1000     ) ) ); writeln();
  doCalc(    1     );   doCalc( impFloatToDouble( doubleToImpFloat(    1     ) ) ); writeln();
  doCalc(    0.1   );   doCalc( impFloatToDouble( doubleToImpFloat(    0.1   ) ) ); writeln();
  doCalc(    0.01  );   doCalc( impFloatToDouble( doubleToImpFloat(    0.01  ) ) ); writeln();
  doCalc(    0.001 );   doCalc( impFloatToDouble( doubleToImpFloat(    0.001 ) ) ); writeln();

  doCalc(    1.5   );   doCalc( impFloatToDouble( doubleToImpFloat(    1.5   ) ) ); writeln();
  doCalc(    0.15  );   doCalc( impFloatToDouble( doubleToImpFloat(    0.15  ) ) ); writeln();
  doCalc(    0.015 );   doCalc( impFloatToDouble( doubleToImpFloat(    0.015 ) ) ); writeln();

  doCalc(    2/3 );
}

{
  fudge( '.31415926' );
  fudge( '0.31415926' );
  fudge( '3.1415926' );
  fudge( '31415926@-7' );
  fudge( '3.1415926@3' );
  fudge( '3.1415926@3' );
  fudge( '3141.5926' );
  fudge( '3141.5926@2' );

  fudge( '10' );
  fudge( '100' );
  fudge( '1000' );
  fudge( '1' );
  fudge( '0.1' );
  fudge( '0.01' );
  fudge( '0.001' );
  fudge( '1.5' );
  fudge( '0.15' );
  fudge( '0.015' );
}

  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '.31415926' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.31415926' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3.1415926' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '31415926@-7' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3.1415926@3' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3141.5926' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3141.5926@2' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3141.5926@-2' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '3141.5926@-6' ) ) ) ); writeln();
{
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '10' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '100' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '1000' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '1' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.1' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.01' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.001' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '1.5' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.15' ) ) ) ); writeln();
  doCalc( impFloatToDouble( doubleToImpFloat( impFloatToDouble( '0.015' ) ) ) ); writeln();
}
end.
