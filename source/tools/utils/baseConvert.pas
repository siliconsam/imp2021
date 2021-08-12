unit baseConvert;
// for exceptions
{$mode objfpc}

// P U B L I C ======================================================== //
interface

const
	/// list of symbols for integer representations
	digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function intToBaseStr(value: longword; const base: cardinal = 10): string;
function baseStrToInt(const value: string; const base: cardinal = 10): longword;

function baseToBase(
		const value: string;
		const interpretation: cardinal = 10;
		const base: cardinal = 10
	): string;
 
// P R I V A T E ====================================================== //
implementation

uses
	// math unit for inRange and divMod routines
	math,
	// sysutils unit for ERangeError exception
	sysutils;

resourceString
	/// base not within range of available symbols
	errInvalidBase = '↯ b = %0:d! ⇒ b ∉ [%1:d, %2:d]';
	/// supplied character not within domain
	errInvalidSymbol = '↯ v(''%0:s'')↑; b = %1:d';
 
(**
	\brief expresses the value in the desired base
	
	\param value the value to convert
	\param base
	
	\return a string representing the number in given base
*)
function intToBaseStr(value: longword; const base: cardinal = 10): string;
var
	remainder: longword;
begin
	// validity of the base
	if not inRange(base, 2, length(digits)) then
	begin
		raise eRangeError.createFmt(errInvalidBase, [base, 2, length(digits)]);
	end;
	
	// decomposing the value: reverse Horner-scheme
	// The repeat-statement takes the value 0 into account.
	result := emptyStr;
	repeat
	begin
		divMod(value, base, value, remainder);
		// prepend value: intermediate results are read backwards
		result := digits[remainder + 1] + result;
	end
	until value = 0;
end;
 
(**
	\brief transforms the string of a number
	       expressed in the parameter base
	       into the equivalent integer
	
	\param value the representation of the integer
	\param base assume string is in given base
	
	If the string is empty, the result is 0.
	
	Caution:
	No verification of integer overflows.
	Reasonable values have to be used.
	
	\return the integer
*)
function baseStrToInt(const value: string; const base: cardinal = 10): longword;
var
	symbol: char;
	// beware, cardinal is _non-negative_
	digit: cardinal;
begin
	result := 0;
	// Horner-scheme
	for symbol in value do
	begin
		// determine ordinal value of current symbol
		digit := pos(symbol, digits);
		// If symbol wasn't found, pos returns 0.
		// Or possibly the symbol isn't known in the base.
		if not inRange(digit, 1, base) then
		begin
			raise eRangeError.createFmt(errInvalidSymbol, [symbol, base]);
		end;
		// e.g. the symbol '0' is the _first_ character in digits
		// thus the pos function returned 1 => here we subtract one
		dec(digit);
		result := result * base + digit;
	end;
end;

(**
	\brief direct conversion of number expressed in one base to another

	\param value the value to convert from
	\param interpretation the base to interpret the value as
	\param base the base to convert to
*)
function baseToBase(
		const value: string;
		const interpretation: cardinal = 10;
		const base: cardinal = 10
	): string;
begin
	// the case interpretation = base
	// intentionally does not have special treatment for unit tests
	result := intToBaseStr(baseStrToInt(value, interpretation), base);
end;

// end of unit
end.