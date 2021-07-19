void readifrecord(FILE *infile, int *type, int *length, unsigned char *buffer);
void writeobjectrecord(FILE *outfile, int type, int count, unsigned char * data);

// Intermediate file types:
#define IF_OBJ          0 // A - plain object code
#define IF_DATA         1 // B - dataseg offset code word
#define IF_CONST        2 // C - const seg offset code word
#define IF_DISPLAY      3 // D - display seg offset code word
#define IF_JUMP         4 // E - unconditional jump to label
#define IF_JCOND        5 // F - cond jump to label JE, JNE, JG, JGE, JL, JLE, JA, JAE, JB, JBE
#define IF_CALL         6 // G - call a label
#define IF_LABEL        7 // H - define a label
#define IF_FIXUP        8 // I - define location for stack fixup instruction
#define IF_SETFIX       9 // J - stack fixup <location> <amount>
#define IF_REQEXT      10 // K - external name spec
#define IF_REFLABEL    11 // L - reference a label
#define IF_REFEXT      12 // M - external name relative offset code word
#define	IF_BSS         13 // N - BSS segment offset code word
#define IF_COTWORD     14 // O - Constant table word
#define IF_DATWORD     15 // P - Data segment word
#define IF_SWTWORD     16 // Q - switch table entry - actually a label ID
#define	IF_SOURCE      17 // R - name of the source file
#define IF_DEFEXTCODE  18 // S - define a code label that is external
#define IF_DEFEXTDATA  19 // T - define a data label that is external
#define IF_SWT         20 // U - switch table offset code word
#define IF_LINE        21 // V - line number info for debugger
#define IF_ABSEXT      22 // W - external name absolute offset code word (data external)

#define WORDSIZE	4

// Interface to ELF/COFF file writer
void setsize(int section, int s);
void setfile(FILE * out, int offset);
void writebyte(int section, unsigned char b);
void writew16(int section, int w);
void writew32(int section, int w);
void writeblock(int section, unsigned char *buffer, int count);

void flushout();

// definitions of ELF/COFF structures.  Some systems may define these
// for you, but for portability they are provided here...
// Note however that we also define some structure sizes, because the
// lame MS compiler can mess you up when you do "sizeof"

typedef unsigned        Elf32_Addr;     // Unsigned program address
typedef unsigned short  Elf32_Half;     // Unsigned medium integer
typedef unsigned        Elf32_Off;      // Unsigned file offset
typedef int             Elf32_Sword;    // Signed large integer
typedef unsigned        Elf32_Word;     // Unsigned large integer

#define EI_NIDENT	16

typedef struct {
    unsigned char e_ident[EI_NIDENT];
    Elf32_Half  e_type ;
    Elf32_Half  e_machine;
    Elf32_Word  e_version;
    Elf32_Addr  e_entry;
    Elf32_Off   e_phoff;
    Elf32_Off   e_shoff;
    Elf32_Word  e_flags;
    Elf32_Half  e_ehsize;
    Elf32_Half  e_phentsize;
    Elf32_Half  e_phnum;
    Elf32_Half  e_shentsize;
    Elf32_Half  e_shnum;
    Elf32_Half  e_shstrndx;
} Elf32_Ehdr;

// some simple defines to go in some holes here
#define	ET_REL      1   // This is a relocatable object file
#define EM_386      3   // For an Intel 80386
#define EV_CURRENT  1   // in version 1 of ELF

// indexes to the ELF ident string
#define EI_MAG0     0   // File identification
#define EI_MAG1     1   // File identification
#define EI_MAG2     2   // File identification
#define EI_MAG3     3   // File identification
#define EI_CLASS    4   // File class
#define EI_DATA     5   // Data encoding
#define EI_VERSION  6   // File version
#define EI_PAD      7   // Start of padding bytes

#define ELFCLASS32  1   // for the class
#define	ELFDATA2LSB 1   // little endian encoding

// ELF Section Header
typedef struct {
    Elf32_Word  sh_name;
    Elf32_Word  sh_type;
    Elf32_Word  sh_flags;
    Elf32_Addr  sh_addr;
    Elf32_Off   sh_offset;
    Elf32_Word  sh_size;
    Elf32_Word  sh_link;
    Elf32_Word  sh_info;
    Elf32_Word  sh_addralign;
    Elf32_Word  sh_entsize;
} Elf32_Shdr;

// and some section types we will use...
#define SHT_NULL        0
#define SHT_PROGBITS    1
#define SHT_SYMTAB      2
#define SHT_STRTAB      3
#define SHT_RELA        4
#define SHT_HASH        5
#define SHT_DYNAMIC     6
#define SHT_NOTE        7
#define SHT_NOBITS      8
#define SHT_REL         9
#define SHT_SHLIB       10
#define SHT_DYNSYM      11

// section flags...
#define SHF_WRITE       0x1 // writable
#define SHF_ALLOC       0x2 // actually occupies some space
#define SHF_EXECINSTR   0x4 // executable

// ELF symbol table entry
typedef struct {
    Elf32_Word      st_name;
    Elf32_Addr      st_value;
    Elf32_Word      st_size;
    unsigned char   st_info;
    unsigned char   st_other;
    Elf32_Half      st_shndx;
} Elf32_Sym;

// symbol table bindings
#define STB_LOCAL   0
#define STB_GLOBAL  1

// symbol table types
#define STT_NOTYPE  0
#define STT_OBJECT  1
#define STT_FUNC    2
#define STT_SECTION 3
#define STT_FILE    4

// special section indexes
#define SHN_ABS     0xfff1

// relocation entries
typedef struct{
    Elf32_Addr  r_offset;
    Elf32_Word  r_info;
} Elf32_Rel;

// the only likely relocations we'll use
#define R_386_NONE  0
#define R_386_32    1
#define R_386_PC32  2

#define SYMNMLEN    8
#define FILNMLEN    14
#define	DIMNUM      4

struct cofffilehdr
{
    unsigned short  f_magic;    // magic number
    unsigned short  f_nscns;    // number of sections
    long            f_timdat;   // time and date stamp
    long            f_symptr;   // file pointer to symbol table
    long            f_nsyms;    // number of symbol table entries
    unsigned short  f_opthdr;   // size of (opt hdr)
    unsigned short  f_flags;    // flags
};

#define SZFILEHDR	(sizeof(struct cofffilehdr))

struct coffscnhdr
{
    char            s_name[SYMNMLEN];   // section name
    long            s_paddr;            // physical address
    long            s_vaddr;            // virtual address
    long            s_size;             // section size
    long            s_scnptr;           // file ptr to raw data
    long            s_relptr;           // file pointer to relocation list
    long            s_lnnoptr;          // file point to line numbers
    unsigned short  s_nreloc;           // number of relocations
    unsigned short  s_nlnno;            // number of line numbers
    long            s_flags;            // section flags
};

#define SZSECHDR	(sizeof(struct coffscnhdr))

struct coffreloc
{
    long            r_vaddr;    // (virtual) address of reference
    long            r_symndx;   // index into symbol table
    unsigned short  r_type;     // relocation type
};

#define SZRELOC		10

struct cofflineno
{
    union
    {
        long    l_symndx;
        long    l_paddr;
    } l_addr;
    unsigned short  l_lnno;
};

#define	SZLINENO    6

struct coffsyment
{
    union
    {
        char        n_name[SYMNMLEN];   // the actual name (if <= 8 chars)
        struct
        {
            long    n_zeroes;           // == 0L if the name is in the string table
            long    n_offset;           // the string table pointer
        } n_n;
    } n;
    long            n_value;            // value of the symbol
    short           n_scnum;            // section number
    unsigned short  n_type;             // type and derived type
    char            n_sclass;           // storage class
    char            n_numaux;           // number of auxilliary entries
};

#define SZSYMENT    18

struct coffauxscn
{
    long            x_scnlen;   // section length
    unsigned short  x_nreloc;   // number of relocations
    unsigned short  x_nlnno;    // number of line numbers
    long            x_chsum;    // COMDAT checksum
    unsigned short  x_secno;    // COMDAT section number
    unsigned short  x_selno;    // COMDAT selection number
    unsigned short  x_pad;      // not used
};

