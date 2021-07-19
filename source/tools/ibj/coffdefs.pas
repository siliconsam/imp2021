{ **************************************** }
{ *                                      * }
{ * Copyright (c) 2020 J.D.McMullin PhD. * }
{   All rights reserved.                 * }
{ *                                      * }
{ **************************************** }
unit coffdefs;
interface
  // definitions of COFF structures.  Some systems may define these
  // for you, but for portability they are provided here...
  // Note however that we also define some structure sizes.
  // Beware! The MS C compiler can mess you up when you do "sizeof"
  // Values and record definitions taken from 
const
  SYMNMLEN = 8;
  FILNMLEN = 14;
  DIMNUM = 4;
  SZRELOC = 10;
  SZLINENO = 6;
  SZSYMENT = 18;  // Can be used for ALL symbol entry records

  // FileHeader Magic number
  IMAGE_FILE_MACHINE_UNKNOWN   = $0;    // The contents of this field are assumed to be applicable to any machine type
  IMAGE_FILE_MACHINE_AM33      = $1d3;  // Matsushita AM33
  IMAGE_FILE_MACHINE_AMD64     = $8664; // x64
  IMAGE_FILE_MACHINE_ARM       = $1c0;  // ARM little endian
  IMAGE_FILE_MACHINE_ARMNT     = $1c4;  // ARMv7 (or higher) Thumb mode only
  IMAGE_FILE_MACHINE_ARM64     = $aa64; // ARMv8 in 64-bit mode
  IMAGE_FILE_MACHINE_EBC       = $ebc;  // EFI byte code
  IMAGE_FILE_MACHINE_I386      = $14c;  // Intel 386 or later processors and compatible processors
  IMAGE_FILE_MACHINE_IA64      = $200;  // Intel Itanium processor family
  IMAGE_FILE_MACHINE_M32R      = $9041; // Mitsubishi M32R little endian
  IMAGE_FILE_MACHINE_MIPS16    = $266;  // MIPS16
  IMAGE_FILE_MACHINE_MIPSFPU   = $366;  // MIPS with FPU
  IMAGE_FILE_MACHINE_MIPSFPU16 = $466;  // MIPS16 with FPU
  IMAGE_FILE_MACHINE_POWERPC   = $1f0;  // Power PC little endian
  IMAGE_FILE_MACHINE_POWERPCFP = $1f1;  // Power PC with floating point support
  IMAGE_FILE_MACHINE_R4000     = $166;  // MIPS little endian
  IMAGE_FILE_MACHINE_SH3       = $1a2;  // Hitachi SH3
  IMAGE_FILE_MACHINE_SH3DSP    = $1a3;  // Hitachi SH3 DSP
  IMAGE_FILE_MACHINE_SH4       = $1a6;  // Hitachi SH4
  IMAGE_FILE_MACHINE_SH5       = $1a8;  // Hitachi SH5
  IMAGE_FILE_MACHINE_THUMB     = $1c2;  // ARM or Thumb (“interworking”)
  IMAGE_FILE_MACHINE_WCEMIPSV2 = $169;  // MIPS little-endian WCE v2

  // FileHeader flags (used for image files)
  IMAGE_FILE_RELOCS_STRIPPED         = $0001;	// Image only, Windows CE, and Windows NT® and later. This indicates that the file does not contain base relocations and must therefore be loaded at its preferred base address. If the base address is not available, the loader reports an error. The default behavior of the linker is to strip base relocations from executable (EXE) files.
  IMAGE_FILE_EXECUTABLE_IMAGE        = $0002; // Image only. This indicates that the image file is valid and can be run. If this flag is not set, it indicates a linker error.
  IMAGE_FILE_LINE_NUMS_STRIPPED      = $0004; // COFF line numbers have been removed. This flag is deprecated and should be zero.
  IMAGE_FILE_LOCAL_SYMS_STRIPPED     = $0008; // COFF symbol table entries for local symbols have been removed. This flag is deprecated and should be zero.
  IMAGE_FILE_AGGRESSIVE_WS_TRIM      = $0010; // Obsolete. Aggressively trim working set. This flag is deprecated for Windows 2000 and later and must be zero.
  IMAGE_FILE_LARGE_ADDRESS_AWARE     = $0020; // Application can handle > 2 GB addresses.
  IMAGE_FILE_RESERVED                = $0040; // This flag is reserved for future use.
  IMAGE_FILE_BYTES_REVERSED_LO       = $0080; // Little endian: the least significant bit (LSB) precedes the most significant bit (MSB) in memory. This flag is deprecated and should be zero.
  IMAGE_FILE_32BIT_MACHINE           = $0100; // Machine is based on a 32-bit-word architecture.
  IMAGE_FILE_DEBUG_STRIPPED          = $0200; // Debugging information is removed from the image file.
  IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = $0400; // If the image is on removable media, fully load it and copy it to the swap file.
  IMAGE_FILE_NET_RUN_FROM_SWAP       = $0800; // If the image is on network media, fully load it and copy it to the swap file.
  IMAGE_FILE_SYSTEM                  = $1000; // The image file is a system file, not a user program.
  IMAGE_FILE_DLL                     = $2000; // The image file is a dynamic-link library (DLL). Such files are considered executable files for almost all purposes, although they cannot be directly run.
  IMAGE_FILE_UP_SYSTEM_ONLY          = $4000; // The file should be run only on a uniprocessor machine.
  IMAGE_FILE_BYTES_REVERSED_HI       = $8000; // Big endian: the MSB precedes the LSB in memory. This flag is deprecated and should be zero.

  // SectionHeader flags
  IMAGE_SCN_CNT_CODE               = $00000020; // The section contains executable code.
  IMAGE_SCN_CNT_INITIALIZED_DATA   = $00000040; // The section contains initialized data.
  IMAGE_SCN_CNT_UNINITIALIZED_DATA = $00000080; // The section contains uninitialized data.
  IMAGE_SCN_LNK_INFO               = $00000200; // The section contains comments or other information. The .drectve section has this type. This is valid for object files only.
  IMAGE_SCN_LNK_REMOVE             = $00000800; // The section will not become part of the image. This is valid only for object files.
  IMAGE_SCN_LNK_COMDAT             = $00001000; // The section contains COMDAT data. For more information, see section 5.5.6, “COMDAT Sections (Object Only).” This is valid only for object files.
  IMAGE_SCN_GPREL                  = $00008000; // The section contains data referenced through the global pointer (GP).
  IMAGE_SCN_MEM_16BIT              = $00020000; // For ARM machine types, the section contains Thumb code.  Reserved for future use with other machine types.
  IMAGE_SCN_ALIGN_1BYTES           = $00100000; // Align data on a 1-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_2BYTES           = $00200000; // Align data on a 2-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_4BYTES           = $00300000; // Align data on a 4-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_8BYTES           = $00400000; // Align data on an 8-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_16BYTES          = $00500000; // Align data on a 16-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_32BYTES          = $00600000; // Align data on a 32-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_64BYTES          = $00700000; // Align data on a 64-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_128BYTES         = $00800000; // Align data on a 128-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_256BYTES         = $00900000; // Align data on a 256-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_512BYTES         = $00A00000; // Align data on a 512-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_1024BYTES        = $00B00000; // Align data on a 1024-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_2048BYTES        = $00C00000; // Align data on a 2048-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_4096BYTES        = $00D00000; // Align data on a 4096-byte boundary. Valid only for object files.
  IMAGE_SCN_ALIGN_8192BYTES        = $00E00000; // Align data on an 8192-byte boundary. Valid only for object files.
  IMAGE_SCN_LNK_NRELOC_OVFL        = $01000000; // The section contains extended relocations.
  IMAGE_SCN_MEM_DISCARDABLE        = $02000000; // The section can be discarded as needed.
  IMAGE_SCN_MEM_NOT_CACHED         = $04000000; // The section cannot be cached.
  IMAGE_SCN_MEM_NOT_PAGED          = $08000000; // The section is not pageable.
  IMAGE_SCN_MEM_SHARED             = $10000000; // The section can be shared in memory.
  IMAGE_SCN_MEM_EXECUTE            = $20000000; // The section can be executed as code.
  IMAGE_SCN_MEM_READ               = $40000000; // The section can be read.
  IMAGE_SCN_MEM_WRITE              = $80000000; // The section can be written to.

  // i386 relocation types
  IMAGE_REL_I386_ABSOLUTE = $0000; // The relocation is ignored.
  IMAGE_REL_I386_DIR32    = $0006; // The target’s 32-bit VA.
  IMAGE_REL_I386_DIR32NB  = $0007; // The target’s 32-bit RVA.
  IMAGE_REL_I386_SECTION  = $000A; // The 16-bit section index of the section that contains the target. This is used to support debugging information.
  IMAGE_REL_I386_SECREL   = $000B; // The 32-bit offset of the target from the beginning of its section. This is used to support debugging information and static thread local storage.
  IMAGE_REL_I386_TOKEN    = $000C; // The CLR token.
  IMAGE_REL_I386_SECREL7  = $000D; // A 7-bit offset from the base of the section that contains the target.
  IMAGE_REL_I386_REL32    = $0014; // The 32-bit relative displacement of the target. This supports the x86 relative branch and call instructions.

  // LSB of Type
  IMAGE_SYM_TYPE_NULL   = 0;  // No type information or unknown base type. Microsoft tools use this setting
  IMAGE_SYM_TYPE_VOID   = 1;  // No valid type; used with void pointers and functions
  IMAGE_SYM_TYPE_CHAR   = 2;  // A character (signed byte)
  IMAGE_SYM_TYPE_SHORT  = 3;  // A 2-byte signed integer
  IMAGE_SYM_TYPE_INT    = 4;  // A natural integer type (normally 4 bytes in Windows)
  IMAGE_SYM_TYPE_LONG   = 5;  // A 4-byte signed integer
  IMAGE_SYM_TYPE_FLOAT  = 6;  // A 4-byte floating-point number
  IMAGE_SYM_TYPE_DOUBLE = 7;  // An 8-byte floating-point number
  IMAGE_SYM_TYPE_STRUCT = 8;  // A structure
  IMAGE_SYM_TYPE_UNION  = 9;  // A union
  IMAGE_SYM_TYPE_ENUM   = 10; // An enumerated type
  IMAGE_SYM_TYPE_MOE    = 11; // A member of enumeration (a specific value)
  IMAGE_SYM_TYPE_BYTE   = 12; // A byte; unsigned 1-byte integer
  IMAGE_SYM_TYPE_WORD   = 13; // A word; unsigned 2-byte integer
  IMAGE_SYM_TYPE_UINT   = 14; // An unsigned integer of natural size (normally, 4 bytes)
  IMAGE_SYM_TYPE_DWORD  = 15; // An unsigned 4-byte integer
  IMAGE_SYM_TYPE_MSOFT  = 32; // Microsoft hack??

  // MSB of Type
  IMAGE_SYM_DTYPE_NULL     = 0; // No derived type; the symbol is a simple scalar variable. 
  IMAGE_SYM_DTYPE_POINTER  = 1; // The symbol is a pointer to base type.
  IMAGE_SYM_DTYPE_FUNCTION = 2; // The symbol is a function that returns a base type.
  IMAGE_SYM_DTYPE_ARRAY    = 3; // The symbol is an array of base type.

  // Symbol Classes
  IMAGE_SYM_CLASS_END_OF_FUNCTION  = $FF; // == -1 A special symbol that represents the end of function, for debugging purposes.
  IMAGE_SYM_CLASS_NULL             =   0; // No assigned storage class.
  IMAGE_SYM_CLASS_AUTOMATIC        =   1; // The automatic (stack) variable. The Value field specifies the stack frame offset.
  IMAGE_SYM_CLASS_EXTERNAL         =   2; // A value that Microsoft tools use for external symbols. The Value field indicates the size if the section number is IMAGE_SYM_UNDEFINED (0). If the section number is not zero, then the Value field specifies the offset within the section.
  IMAGE_SYM_CLASS_STATIC           =   3; // The offset of the symbol within the section. If the Value field is zero, then the symbol represents a section name.
  IMAGE_SYM_CLASS_REGISTER         =   4; // A register variable. The Value field specifies the register number.
  IMAGE_SYM_CLASS_EXTERNAL_DEF     =   5; // A symbol that is defined externally.
  IMAGE_SYM_CLASS_LABEL            =   6; // A code label that is defined within the module. The Value field specifies the offset of the symbol within the section.
  IMAGE_SYM_CLASS_UNDEFINED_LABEL  =   7; // A reference to a code label that is not defined.
  IMAGE_SYM_CLASS_MEMBER_OF_STRUCT =   8; // The structure member. The Value field specifies the nth member.
  IMAGE_SYM_CLASS_ARGUMENT         =   9; // A formal argument (parameter) of a function. The Value field specifies the nth argument.
  IMAGE_SYM_CLASS_STRUCT_TAG       =  10; // The structure tag-name entry.
  IMAGE_SYM_CLASS_MEMBER_OF_UNION  =  11; // A union member. The Value field specifies the nth member.
  IMAGE_SYM_CLASS_UNION_TAG        =  12; // The Union tag-name entry.
  IMAGE_SYM_CLASS_TYPE_DEFINITION  =  13; // A Typedef entry.
  IMAGE_SYM_CLASS_UNDEFINED_STATIC =  14; // A static data declaration.
  IMAGE_SYM_CLASS_ENUM_TAG         =  15; // An enumerated type tagname entry.
  IMAGE_SYM_CLASS_MEMBER_OF_ENUM   =  16; // A member of an enumeration. The Value field specifies the nth member.
  IMAGE_SYM_CLASS_REGISTER_PARAM   =  17; // A register parameter.
  IMAGE_SYM_CLASS_BIT_FIELD        =  18; // A bit-field reference. The Value field specifies the nth bit in the bit field.
  IMAGE_SYM_CLASS_BLOCK            = 100; // A .bb (beginning of block) or .eb (end of block) record. The Value field is the relocatable address of the code location.
  IMAGE_SYM_CLASS_FUNCTION         = 101; // A value that Microsoft tools use for symbol records that define the extent of a function: begin function (.bf), end function (.ef), and lines in function (.lf). For .lf records, the Value field gives the number of source lines in the function. For .ef records, the Value field gives the size of the function code.
  IMAGE_SYM_CLASS_END_OF_STRUCT    = 102; // An end-of-structure entry.
  IMAGE_SYM_CLASS_FILE             = 103; // A value that Microsoft tools, as well as traditional COFF format, use for the source-file symbol record. The symbol is followed by auxiliary records that name the file.
  IMAGE_SYM_CLASS_SECTION          = 104; // A definition of a section (Microsoft tools use STATIC storage class instead).
  IMAGE_SYM_CLASS_WEAK_EXTERNAL    = 105; // A weak external. For more information, see section 5.5.3, “Auxiliary Format 3: Weak Externals.”
  IMAGE_SYM_CLASS_CLR_TOKEN        = 107; // A CLR token symbol. The name is an ASCII string that consists of the hexadecimal value of the token. For more information, see section 5.5.7, “CLR Token Definition (Object Only).”

type
  cofffilehdr =
  packed record
	f_magic  : word;    // magic number
	f_nscns  : word;    // number of sections
	f_timdat : longint; // time and date stamp
	f_symptr : longint;	// file pointer to symbol table
	f_nsyms  : longint; // number of symbol table entries
	f_opthdr : word;    // size of (opt hdr)
	f_flags  : word;    // flags
  end;

  coffscnhdr =
  packed record
    s_name    : array[0..(SYMNMLEN-1)] of char; // section name
    s_paddr   : longint; // physical address
    s_vaddr   : longint; // virtual address
    s_size    : longint; // section size
    s_scnptr  : longint; // file ptr to raw data
    s_relptr  : longint; // file pointer to relocation list
    s_lnnoptr : longint; // file point to line numbers
    s_nreloc  : word;    // number of relocations
    s_nlnno   : word;    // number of line numbers
    s_flags   : longword; // section flags
  end;

  coffreloc =
  packed record
    r_vaddr  : longint; // (virtual) address of reference
    r_symndx : longint; // index into symbol table
    r_type   : word;    // relocation type
  end;

  s_addr =
  packed record
    case boolean of
    false: (l_symndx : longint;);
    true:  (l_paddr  : longint;);
  end;

  cofflineno =
  packed record
	l_addr : s_addr;
	l_lnno : word;
  end;

  s_n_n =
  packed record
    n_zeroes : longint; // == 0L if the name is in the string table
    n_offset : longint; // the string table pointer
  end;

  s_n = packed record
    case boolean of
    false: (n_name : array[0..SYMNMLEN-1] of char;); // the actual name (if <= 8 chars)
    true:  (n_n    : s_n_n;);
  end;

  coffsyment =
  packed record
    n        : s_n;
    n_value  : longint;  // value of the symbol
    n_scnum  : smallint; // section number
    n_type   : word;     // type and derived type
    n_sclass : byte;     // storage class
    n_numaux : byte;     // number of auxiliary entries
  end;

{ another batch of const declarations: defines various record sizes }
const
  SZFILEHDR    = sizeof(cofffilehdr);
  SZSECHDR     = sizeof(coffscnhdr);
  SZCOFFRELOC  = sizeof(coffreloc);
  SZCOFFLINENO = sizeof(cofflineno);
  SZCOFFSYMENT = sizeof(coffsyment);

type
  // The following coffauxXXX records have the same size as coffsyment (to ensure symbol table can be accessed as an array
  // The various coffauxXXX records have different layouts to support the associated coffsyment record;

  // Function defn: used storage class = EXTERNAL and Type value = function (0x20), and section number > 0.
  // x_tagidx   : The symbol-table index of the corresponding .bf (begin function) symbol record.
  // x_totsz    : The size of the executable code for the function itself.
  //              If the function is in its own section, the SizeOfRawData in the section header is greater or equal to this field,
  //              depending on alignment considerations.
  // x_lnnoptr  : The file offset of the first COFF line-number entry for the function, or zero if none exists.
  //              For more information, see section 5.3, “COFF Line Numbers (Deprecated).”
  // x_nxtfnptr : The symbol-table index of the record for the next function.
  //              If the function is the last in the symbol table, this field is set to zero.
  coffaux1 =
  packed record
    x_tagidx   : longword;
    x_totsz    : longint;
    x_lnnoptr  : longint;
    x_nxtfnptr : longint;
    x_unused   : word; // Unused (== padding)
  end;

  // For each function definition in the symbol table, three items describe the beginning, ending, and number of lines.
  // Each of these symbols has storage class FUNCTION (101):
  // • A symbol record named .bf (begin function). The Value field is unused.
  // • A symbol record named .lf (lines in function). The Value field == number of lines in the function.
  // • A symbol record named .ef (end of function). The Value field has value as x_totsz field in coffaux1 (function-definition aux record).
  //
  // The .bf and .ef symbol records (but not .lf records) are followed by an auxiliary record with the following format.
  //
  // x_lnno      : The actual line number (1, 2, 3, and so on) within the source file, corresponding to the .bf or .ef record.
  // x_nxtfunptr : (.bf only) The symbol-table index of next .bf symbol. 0 => last entry. It is not used for .ef records.
  coffaux2 =
  packed record
    x_unused0   : longint;
    x_lnno      : word;
    x_unused1   : longint;
    x_unused2   : word;
    x_nxtfunptr : longint;
    x_unused3   : word;
  end;

  // “Weak externals” are a mechanism for object files that allows flexibility at link time.
  // A module can contain an unresolved external symbol (sym1), but it can also include
  // an auxiliary record that indicates that if sym1 is not present at link time,
  // another external symbol (sym2) is used to resolve references instead.
  //
  // If a definition of sym1 is linked, then an external reference to the symbol is resolved normally.
  // If a definition of sym1 is not linked, then all references to the weak external for sym1 refer to sym2 instead.
  // The external symbol, sym2, must always be linked; typically,
  // it is defined in the module that contains the weak reference to sym1.
  // Weak externals are represented by a symbol table record with EXTERNAL storage class, UNDEF section number, and a value of zero.
  // The weak-external symbol record is followed by an auxiliary record with the following format.
  coffaux3 =
  packed record
    x_tagidx : longint; // The symbol-table index of sym2, the symbol to be linked if sym1 is not found.
    x_flags  : longint; // A value of IMAGE_WEAK_EXTERN_SEARCH_NOLIBRARY indicates that no library search for sym1 should be performed.
                        // A value of IMAGE_WEAK_EXTERN_SEARCH_LIBRARY indicates that a library search for sym1 should be performed.
                        // A value of IMAGE_WEAK_EXTERN_SEARCH_ALIAS indicates that sym1 is an alias for sym2.
    x_unused0 : longint; // Actually next 10 bytes are unused
    x_unused1 : longint;
    x_unused2 : word;
  end;

  // This format follows a symbol-table record with storage class FILE (103).
  // The symbol name itself should be .file
  // The auxiliary record that follows it gives the name of a source-code file.
  // x_filename : string that gives the name of the source file.
  //              This is padded with nulls if it is less than the maximum length.
  // A symbol record might contain > 1 coffaux4 records for long filenames
  coffaux4 =
  packed record
    x_filename : array [0..(SZCOFFSYMENT-1)] of byte;
  end;

  coffauxscn =
  packed record
    x_scnlen : longint; // section length
    x_nreloc : word;    // number of relocations
    x_nlnno  : word;    // number of line numbers
    x_chsum  : longint; // COMDAT checksum
    x_secno  : word;    // COMDAT section number
    x_selno  : word;    // COMDAT selection number
                        // use low byte only
                        // high byte is really additional to x_pad
    x_pad    : word;    // not used
  end;

{ second const declarations: defines various record sizes }
const
  SZCOFFAUXSCN = sizeof(coffauxscn);

  function decodeMagicNumber( magic : word ): string;
  function decodeHeaderFlags( flag : word ): string;
  function decodeSectionFlags( flag : longint ): string;
  function decodei386RelocationType( flag : word ): string;
  function decodeSymbolTypeMSB( w : word ):string;
  function decodeSymbolTypeLSB( w : word ): string;
  function decodeSymbolClass( b : byte ): string;

implementation

  function decodeMagicNumber( magic : word ): string;
  var
    s : string;
  begin
    s := 'UNKNOWN MACHINE';
    if magic = IMAGE_FILE_MACHINE_UNKNOWN   then s := 'ANY MACHINE';
    if magic = IMAGE_FILE_MACHINE_AM33      then s := 'Matsushita AM33';
    if magic = IMAGE_FILE_MACHINE_AMD64     then s := 'x64';
    if magic = IMAGE_FILE_MACHINE_ARM       then s := 'ARM little endian';
    if magic = IMAGE_FILE_MACHINE_ARMNT     then s := 'ARMv7 (or higher) Thumb mode only';
    if magic = IMAGE_FILE_MACHINE_ARM64     then s := 'ARMv8 in 64-bit mode';
    if magic = IMAGE_FILE_MACHINE_EBC       then s := 'EFI byte code';
    if magic = IMAGE_FILE_MACHINE_I386      then s := 'Intel 386 or later processors and compatible processors';
    if magic = IMAGE_FILE_MACHINE_IA64      then s := 'Intel Itanium processor family';
    if magic = IMAGE_FILE_MACHINE_M32R      then s := 'Mitsubishi M32R little endian';
    if magic = IMAGE_FILE_MACHINE_MIPS16    then s := 'MIPS16';
    if magic = IMAGE_FILE_MACHINE_MIPSFPU   then s := 'MIPS with FPU';
    if magic = IMAGE_FILE_MACHINE_MIPSFPU16 then s := 'MIPS16 with FPU';
    if magic = IMAGE_FILE_MACHINE_POWERPC   then s := 'Power PC little endian';
    if magic = IMAGE_FILE_MACHINE_POWERPCFP then s := 'Power PC with floating point support';
    if magic = IMAGE_FILE_MACHINE_R4000     then s := 'MIPS little endian';
    if magic = IMAGE_FILE_MACHINE_SH3       then s := 'Hitachi SH3';
    if magic = IMAGE_FILE_MACHINE_SH3DSP    then s := 'Hitachi SH3 DSP';
    if magic = IMAGE_FILE_MACHINE_SH4       then s := 'Hitachi SH4';
    if magic = IMAGE_FILE_MACHINE_SH5       then s := 'Hitachi SH5';
    if magic = IMAGE_FILE_MACHINE_THUMB     then s := 'ARM or Thumb (“interworking”)';
    if magic = IMAGE_FILE_MACHINE_WCEMIPSV2 then s := 'MIPS little-endian WCE v2';

    decodeMagicNumber := s;
  end;

  function addTo( s,t : string ): string;
  begin
    if (s = '') then addTo := t else addTo := s + chr(10) + t;
  end;

  function decodeHeaderFlags( flag : word ): string;
  var
    s :string;
  begin
    s := '';
    if (flag and IMAGE_FILE_RELOCS_STRIPPED)         = IMAGE_FILE_RELOCS_STRIPPED         then s := addTo( s, 'RELOCS_STRIPPED' );
    if (flag and IMAGE_FILE_EXECUTABLE_IMAGE)        = IMAGE_FILE_EXECUTABLE_IMAGE        then s := addTo( s, 'EXECUTABLE_IMAGE' );
    if (flag and IMAGE_FILE_LINE_NUMS_STRIPPED)      = IMAGE_FILE_LINE_NUMS_STRIPPED      then s := addTo( s, 'LINE_NUMS_STRIPPED' );
    if (flag and IMAGE_FILE_LOCAL_SYMS_STRIPPED)     = IMAGE_FILE_LOCAL_SYMS_STRIPPED     then s := addTo( s, 'LOCAL_SYMS_STRIPPED' );
    if (flag and IMAGE_FILE_AGGRESSIVE_WS_TRIM)      = IMAGE_FILE_AGGRESSIVE_WS_TRIM      then s := addTo( s, 'AGGRESSIVE_WS_TRIM' );
    if (flag and IMAGE_FILE_LARGE_ADDRESS_AWARE)     = IMAGE_FILE_LARGE_ADDRESS_AWARE     then s := addTo( s, 'LARGE_ADDRESS_AWARE' );
    if (flag and IMAGE_FILE_RESERVED)                = IMAGE_FILE_RESERVED                then s := addTo( s, 'FLAG_RESERVED' );
    if (flag and IMAGE_FILE_BYTES_REVERSED_LO)       = IMAGE_FILE_BYTES_REVERSED_LO       then s := addTo( s, 'BYTES_REVERSED_LO' );
    if (flag and IMAGE_FILE_32BIT_MACHINE)           = IMAGE_FILE_32BIT_MACHINE           then s := addTo( s, '32BIT_MACHINE' );
    if (flag and IMAGE_FILE_DEBUG_STRIPPED)          = IMAGE_FILE_DEBUG_STRIPPED          then s := addTo( s, 'DEBUG_STRIPPED' );
    if (flag and IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP) = IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP then s := addTo( s, 'REMOVABLE_RUN_FROM_SWAP' );
    if (flag and IMAGE_FILE_NET_RUN_FROM_SWAP)       = IMAGE_FILE_NET_RUN_FROM_SWAP       then s := addTo( s, 'NET_RUN_FROM_SWAP' );
    if (flag and IMAGE_FILE_SYSTEM)                  = IMAGE_FILE_SYSTEM                  then s := addTo( s, 'SYSTEM' );
    if (flag and IMAGE_FILE_DLL)                     = IMAGE_FILE_DLL                     then s := addTo( s, 'DLL' );
    if (flag and IMAGE_FILE_UP_SYSTEM_ONLY)          = IMAGE_FILE_UP_SYSTEM_ONLY          then s := addTo( s, 'UP_SYSTEM_ONLY' );
    if (flag and IMAGE_FILE_BYTES_REVERSED_HI)       = IMAGE_FILE_BYTES_REVERSED_HI       then s := addTo( s, 'BYTES_REVERSED_HI' );

    decodeHeaderFlags := s;
  end;

  function decodeSectionFlags( flag : longint ): string;
  var
    s : string;
  begin
    s := '';
    if (flag and IMAGE_SCN_CNT_CODE)               = IMAGE_SCN_CNT_CODE               then s := addTo( s, 'CNT_CODE' );
    if (flag and IMAGE_SCN_CNT_INITIALIZED_DATA)   = IMAGE_SCN_CNT_INITIALIZED_DATA   then s := addTo( s, 'CNT_INITIALIZED_DATA' );
    if (flag and IMAGE_SCN_CNT_UNINITIALIZED_DATA) = IMAGE_SCN_CNT_UNINITIALIZED_DATA then s := addTo( s, 'CNT_UNINITIALIZED_DATA' );
    if (flag and IMAGE_SCN_LNK_INFO)               = IMAGE_SCN_LNK_INFO               then s := addTo( s, 'LNK_INFO' );
    if (flag and IMAGE_SCN_LNK_REMOVE)             = IMAGE_SCN_LNK_REMOVE             then s := addTo( s, 'LNK_REMOVE' );
    if (flag and IMAGE_SCN_LNK_COMDAT)             = IMAGE_SCN_LNK_COMDAT             then s := addTo( s, 'LNK_COMDAT' );
    if (flag and IMAGE_SCN_GPREL)                  = IMAGE_SCN_GPREL                  then s := addTo( s, 'GPREL' );
    if (flag and IMAGE_SCN_MEM_16BIT)              = IMAGE_SCN_MEM_16BIT              then s := addTo( s, 'MEM_16BIT' );
    case (flag shr 20) and $f of
 $1:  s := addTo( s, 'ALIGN_1BYTES' );
 $2:  s := addTo( s, 'ALIGN_2BYTES' );
 $3:  s := addTo( s, 'ALIGN_4BYTES' );
 $4:  s := addTo( s, 'ALIGN_8BYTES' );
 $5:  s := addTo( s, 'ALIGN_16BYTES' );
 $6:  s := addTo( s, 'ALIGN_32BYTES' );
 $7:  s := addTo( s, 'ALIGN_64BYTES' );
 $8:  s := addTo( s, 'ALIGN_128BYTES' );
 $9:  s := addTo( s, 'ALIGN_256BYTES' );
 $A:  s := addTo( s, 'ALIGN_512BYTES' );
 $B:  s := addTo( s, 'ALIGN_1024BYTES' );
 $C:  s := addTo( s, 'ALIGN_2048BYTES' );
 $D:  s := addTo( s, 'ALIGN_4096BYTES' );
 $E:  s := addTo( s, 'ALIGN_8192BYTES' );
    else
    end;
    if (flag and IMAGE_SCN_LNK_NRELOC_OVFL)        = IMAGE_SCN_LNK_NRELOC_OVFL        then s := addTo( s, 'LNK_NRELOC_OVFL' );
    if (flag and IMAGE_SCN_MEM_DISCARDABLE)        = IMAGE_SCN_MEM_DISCARDABLE        then s := addTo( s, 'MEM_DISCARDABLE' );
    if (flag and IMAGE_SCN_MEM_NOT_CACHED)         = IMAGE_SCN_MEM_NOT_CACHED         then s := addTo( s, 'MEM_NOT_CACHED' );
    if (flag and IMAGE_SCN_MEM_NOT_PAGED)          = IMAGE_SCN_MEM_NOT_PAGED          then s := addTo( s, 'MEM_NOT_PAGED' );
    if (flag and IMAGE_SCN_MEM_SHARED)             = IMAGE_SCN_MEM_SHARED             then s := addTo( s, 'MEM_SHARED' );
    if (flag and IMAGE_SCN_MEM_EXECUTE)            = IMAGE_SCN_MEM_EXECUTE            then s := addTo( s, 'MEM_EXECUTE' );
    if (flag and IMAGE_SCN_MEM_READ)               = IMAGE_SCN_MEM_READ               then s := addTo( s, 'MEM_READ' );
    if (flag and IMAGE_SCN_MEM_WRITE)              = IMAGE_SCN_MEM_WRITE              then s := addTo( s, 'MEM_WRITE' );

    decodeSectionFlags := s;
  end;

  function decodei386RelocationType( flag : word ): string;
  var
    s :string;
  begin
    s := '';
    if (flag = IMAGE_REL_I386_ABSOLUTE) then s := 'ABSOLUTE';
    if (flag = IMAGE_REL_I386_DIR32)    then s := 'DIR32';
    if (flag = IMAGE_REL_I386_DIR32NB)  then s := 'DIR32NB';
    if (flag = IMAGE_REL_I386_SECTION)  then s := 'SECTION';
    if (flag = IMAGE_REL_I386_SECREL)   then s := 'SECREL';
    if (flag = IMAGE_REL_I386_TOKEN)    then s := 'TOKEN';
    if (flag = IMAGE_REL_I386_SECREL7)  then s := 'SECREL7';
    if (flag = IMAGE_REL_I386_REL32)    then s := 'REL32';

    decodei386RelocationType := s;
  end;

  function decodeSymbolTypeMSB( w : word ): string;
  var
    s : string;
  begin
    case ((w shr 8) and $ff) of
IMAGE_SYM_DTYPE_NULL:     s := 'notype';
IMAGE_SYM_DTYPE_POINTER:  s := 'pointer';
IMAGE_SYM_DTYPE_FUNCTION: s := 'function';
IMAGE_SYM_DTYPE_ARRAY:    s := 'array';
    else
      s := '';
    end;
    decodeSymbolTypeMSB := s;
  end;

  function decodeSymbolTypeLSB( w : word ): string;
  var
    s : string;
  begin
    case (w and $ff) of
IMAGE_SYM_TYPE_NULL:   s := '  '; // null
IMAGE_SYM_TYPE_VOID:   s := 'void';
IMAGE_SYM_TYPE_CHAR:   s := 'char';
IMAGE_SYM_TYPE_SHORT:  s := 'short';
IMAGE_SYM_TYPE_INT:    s := 'int';
IMAGE_SYM_TYPE_LONG:   s := 'long';
IMAGE_SYM_TYPE_FLOAT:  s := 'float';
IMAGE_SYM_TYPE_DOUBLE: s := 'double';
IMAGE_SYM_TYPE_STRUCT: s := 'struct';
IMAGE_SYM_TYPE_UNION:  s := 'union';
IMAGE_SYM_TYPE_ENUM:   s := 'enum';
IMAGE_SYM_TYPE_MOE:    s := 'moe';
IMAGE_SYM_TYPE_BYTE:   s := 'byte';
IMAGE_SYM_TYPE_WORD:   s := 'word';
IMAGE_SYM_TYPE_UINT:   s := 'uint';
IMAGE_SYM_TYPE_DWORD:  s := 'dword';
IMAGE_SYM_TYPE_MSOFT:  s := '()';
    else
      s := '?? unknown type ??';
    end;
    decodeSymbolTypeLSB := s;
  end;

  function decodeSymbolClass( b : byte ): string;
  var
    s : string;
  begin
    case b of
IMAGE_SYM_CLASS_END_OF_FUNCTION:  s := 'end_of_function';
IMAGE_SYM_CLASS_NULL:             s := 'Null';
IMAGE_SYM_CLASS_AUTOMATIC:        s := 'Automatic';
IMAGE_SYM_CLASS_EXTERNAL:         s := 'External';
IMAGE_SYM_CLASS_STATIC:           s := 'Static';
IMAGE_SYM_CLASS_REGISTER:         s := 'Register';
IMAGE_SYM_CLASS_EXTERNAL_DEF:     s := 'external_def';
IMAGE_SYM_CLASS_LABEL:            s := 'Label';
IMAGE_SYM_CLASS_UNDEFINED_LABEL:  s := 'undefined_label';
IMAGE_SYM_CLASS_MEMBER_OF_STRUCT: s := 'member_of_struct';
IMAGE_SYM_CLASS_ARGUMENT:         s := 'Argument';
IMAGE_SYM_CLASS_STRUCT_TAG:       s := 'struct_tag';
IMAGE_SYM_CLASS_MEMBER_OF_UNION:  s := 'member_of_union';
IMAGE_SYM_CLASS_UNION_TAG:        s := 'union_tag';
IMAGE_SYM_CLASS_TYPE_DEFINITION:  s := 'type_definition';
IMAGE_SYM_CLASS_UNDEFINED_STATIC: s := 'undefined_static';
IMAGE_SYM_CLASS_ENUM_TAG:         s := 'enum_tag';
IMAGE_SYM_CLASS_MEMBER_OF_ENUM:   s := 'member_of_enum';
IMAGE_SYM_CLASS_REGISTER_PARAM:   s := 'register_param';
IMAGE_SYM_CLASS_BIT_FIELD:        s := 'bit_field';
IMAGE_SYM_CLASS_BLOCK:            s := 'Block';
IMAGE_SYM_CLASS_FUNCTION:         s := 'Function';
IMAGE_SYM_CLASS_END_OF_STRUCT:    s := 'end_of_struct';
IMAGE_SYM_CLASS_FILE:             s := 'Filename';
IMAGE_SYM_CLASS_SECTION:          s := 'Section';
IMAGE_SYM_CLASS_WEAK_EXTERNAL:    s := 'weak_external';
IMAGE_SYM_CLASS_CLR_TOKEN:        s := 'clr_token';
    else
      s := '?? unknown class ??';
    end;
    decodeSymbolClass := s;
  end;

end.
