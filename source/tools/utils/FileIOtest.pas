{ This program demonstrates the various file I/O functions }
{ the FileCreate/FileSeek/FileReed/FileTruncate functions }
{ these have two variants longint and int64 }
{   where the parameters and results are either longint or int64 }

{ This example program uses the longint variants }
{ If you want to use the int64 variants of the FileI/O then }
{    simply replace all text references to longint by int64 }
program Example37;
uses sysutils;

const
    MaxLoc = 100;
    ItemSize = sizeof( longint );
    ItemType = 'longint';
var
    i : integer;
    j : longint; { extended value of i }
    k,f : longint;

begin
    { create an empty file, ready to write to }
    f := FileCreate( 'test.dat' );
    { quit if we couldn't create the file for whatever reason }
    if (f = -1) then Halt( 1 );
    { Ok, file successfully created }
    { so, write the specified count of values to the file }
    { We are looping over an ordinal range 0..MaxLoc }
    for i := 0 to MaxLoc do
    begin
        { Convert i to be a variable of ItemSize bytes }
        j := i;
        { Now write the variable }
        FileWrite( f, j, ItemSize );
    end;
    { and close the file }
    FileClose( f );

    { Check file has expected contents }
    { open the newly created file so we can read it }
    f := FileOpen( 'test.dat', fmOpenRead );
    for i := 0 to MaxLoc do
    begin
        { Convert i to be a variable of ItemSize bytes }
        j := i;
        FileRead( f, k, ItemSize );
        if (j <> k) then Writeln( 'Mismatch at file position ', i )
    end;
    FileClose( f );

    { Now, do a random read of the file }
    { open file for read and write access }
    f := FileOpen( 'test.dat', fmOpenReadWrite );
    { start at the beginning of the file }
    FileSeek( f, 0, fsFromBeginning );
    { ready the "dice" }
    Randomize;

    { now keep throwing the "dice" }
    repeat
        { choose a random location }
        i := Random(MaxLoc);
        FileSeek( f, i*ItemSize, fsFromBeginning );

        { Now, read from that location }
        FileRead( f, k, ItemSize );
        Writeln( 'Random read @file[',i,'] = ', k );

        { as soon as the location > 80 we stop the "dice" rolls }
    until  (i > 80);

    { Now, do a random read and possibly tweak value and write new value }
    repeat
        i := Random(MaxLoc);
        FileSeek( f, i*ItemSize, fsFromBeginning );
        FileRead( f, k, ItemSize );
        Writeln( 'Random read before write @file[',i,'] = ', k );

        { tweak value if value read is > 50 }
        { also means we might only tweak file locations >= 50 }
        { assuming file location[ n ] == n }
        { where we are counting locations in chunks of sizeOf( longint ) bytes }
        if (k >= 50) then
        begin
            k := MaxLoc - k;
            { FileRead moved file pointer sizeof( longint ) bytes }
            { so, we need to move back before a FileWrite }
            { move back to read location }

            { fsFromBeginning => move to location from start of file }
{
            FileSeek( f, i*sizeof( longint ), fsFromBeginning );
}
            { fsFromCurrent => move to location relative to current file location }
            FileSeek( f, -ItemSize, fsFromCurrent );
            FileWrite( f, k, ItemSize );
        end;
        
        { only examine the i <= 80 file locations }
    until  (i > 80);

    { Now, do a random read of the file }
    { find a tweaked value }
    repeat
        i := Random(MaxLoc);
        FileSeek( f, i*ItemSize, fsFromBeginning );
        FileRead( f, k, ItemSize );
        Writeln( 'Random read after write @file[',i,'] = ', k );
        { Convert i to be a variable of ItemSize bytes }
        j := i;
        { does the index i match the stored value }
    until  (j <> k);
    { ok, finished tweking the file so save the contents }
    FileClose( f );

    { Now, re-open ready to truncate the file }
    f := FileOpen( 'test.dat', fmOpenWrite );
    { only retain the first 50 item values }
    i := 50;
    { ok, truncate the file, because we can }
    If FileTruncate( f, i*ItemSize ) then
    begin
        Write( 'SuccessFully truncated file to ', i*ItemSize, ' bytes' );
        Write( ' ( == ', i, ' ', ItemType, ' )' );
        Writeln( );
    end;
    { save it }
    FileClose( f );

End.
