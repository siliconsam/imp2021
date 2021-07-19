// IMP Compiler for 80386 - ELF pass 3

// This reads an intermediate object file produced by the
// second pass, performs the jump and stack allocation fixups,
// and writes a standard ELF format object file.  It
// reads the input file twice - once to collect all the jump
// and stack information, and then a second time to actually
// write the object file.

// There will be (up to) 12 sections in the ELF file:
//      a pseudo-section containing the file header
//      string table of names        - .strtab
//      the code itself              - .text
//      the constant data            - .rodata
//      the writable (own) data      - .data
//      the switch table(s)          - switch
//      the trap table               - trap
//      the trap end marker          - trapend
//      compiler version             - .comment
//      the symbol table             - .symtab
//      the code relocations         - .rel.text
//      the switch table relocations - .relswitch
//      the trap table relocations   - .reltrap
//      a pseudo-section containing the section header table
//
// On the first pass through we determine the size of each
// section (eliminating any of zero size) and preset the file
// pointers for the scatter-write routines.  On the second pass
// we can then write to the correct places in the file

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "pass3.h"

// ELF Magix String
static char elfmagic[EI_NIDENT] = {
	0x7F, 'E', 'L', 'F', ELFCLASS32, ELFDATA2LSB, EV_CURRENT,
		0, 0, 0, 0, 0, 0, 0, 0, 0
};

// compiler version comment
static char vsncomment[] = "IMP2021 June 2021";
#define SZVSNCMNT   (sizeof(vsncomment))

static char path_buffer[256]; // working areas for file lookup
static int  path_index;       // location of the result in the string table

// So that we can always find the trap table we define two
// special symbols IFF this is a main program block
#define TRAPSTART	"_imptrapbase"
#define	TRAPEND		"_imptrapend"
#define TRAPENDSZ   32

#define MAINPROGNAME "main"

// these willl get put into the string table and the indexes are here
static int trapstart_index;
static int trapend_index;

// Pass 3 builds an in-store model of the application as a series
// literal code blocks, data blocks, and so on.
struct item {
    int what;    // what this block describes
    int address; // the address in the image
    int info;    // type dependent extra information
    int size;    // size this block occupies in the image (generally in bytes)
};

#define MAXITEM 10000
struct item m[MAXITEM];
int nm = 0;

// Jumps and calls all go to logical labels (a label ID is a 16 bit number)
// We collect a simple database of labels and their corresponding code addresses
struct label {
    int labelid;
    int address;
};
#define MAXLABEL 2500
struct label labels[MAXLABEL];
int nl = 1;

// The entry to each routine includes code to move the stack frame for
// local variables.  Pass 2 plants a fixup record at the end of the
// routine.  We use this table to match fixups with their corresponding
// entry sequence, and we also use it to plant trap records
struct stfix {
    int id;     // arbitrary ID passed by Pass 2 (actually derived from P2's nominal code address)
    int hint;   // pointer to the M record corresponding to the entry code
    int events; // events trapped in this subroutine (a 16 bit bitmask)
    int start;  // actual start address of subroutine
    int trap;   // label of the event trap entry point (if events != 0)
    int evfrom; // label of the start of the event protected area
    int end;    // actual end address of subroutine
    int namep;  // pointer to debug name of this routine
};
#define MAXSTACK 500
struct stfix stackfix[MAXSTACK];
int ns = 0;

// The name dictionary is filled by external import or export
// names, zero terminated - the M record points to the first
// character of the corresponding name.
// NOTE - ELF requires that there is always an entry at offset zero
// that is a zero byte (null pointer == null name)
#define MAXNAME 5000
char named[MAXNAME] = { 0, };
int namedp = 1;

// Line number information is collected as the object file is
// written so that we can write a linenumber segment for the
// debugger
struct lineno {
    int line;
    int offset;
};

#define MAXLINENO 4000
struct lineno lines[MAXLINENO];
int nlines = 0;
int lastlinead = -1;	// the code address at the last line record assigned

// Code relocations are interspersed by Pass2 in with the code, but
// are output en-masse in the COFF file.  We count them here because
// we need to know how many there are when constructing the COFF file.
int nreloc = 0;

// As we build the external symbol table we count them too...
int nsymdefs = 0;

// Pass 2 passes on all symbols that are "spec'ed", and allocates an index
// in sequence.  We check to see if they ever actually get used so that we
// can prune the unwanted ones, and remap the indexes into the symbol table
// accordingly...
struct symspec {
    int used;       // a boolean flag
    int p3index;    // the actual symbol index
    int isdata;     // is the symbol external data (=1) or code (=0)
};

#define MAXSPECS 250
struct symspec specs[MAXSPECS];
int nspecs = 0;

// Pass3 needs to know whether this is a main program or a
// file of external routines, because main programs get a
// special symbol defined for the trap table
int mainprog = 0;

//////// Database routines

// report this line number as being at this address
static void newlineno(int line, int addr)
{
    // is this line the same address as we already have?
    if (addr == lastlinead)	// lines have advanced, but code didn't
    {
        lines[nlines-1].line = line;    // update current record
    }
    else
    {
        if (nlines < MAXLINENO)		// only if there is room
        {
            lines[nlines].line = line;
            lines[nlines].offset = addr;
            nlines += 1;
            lastlinead = addr;
        }
    }
}

// return the index of the next item block
static int newitem()
{
    if (nm == MAXITEM)
    {
        fprintf(stderr, "Program too big\n");
        fprintf(stderr, "Increase the value of MAXITEM\n");
        exit(1);
    }
    nm = nm + 1;
    return (nm - 1);
}

// return the index of the next label record
static int newlabel()
{
    if (nl == MAXLABEL)
    {
        fprintf(stderr, "Too many labels\n");
        fprintf(stderr, "Increase the value of MAXLABEL\n");
        exit(1);
    }
    nl = nl + 1;
    return (nl - 1);
}

// return the index of the next procedure/stack record
static int newstack()
{
    if (ns == MAXSTACK)
    {
        fprintf(stderr, "Too many subroutines\n");
        fprintf(stderr, "Increase the value of MAXSTACK\n");
        exit(1);
    }
    ns = ns + 1;
    return (ns - 1);
}

// copy a new name into the name dictionary, and return
// the index of the first character
static int newname(char * name)
{
    int l;

    l = strlen(name);
    if ((l + namedp) >= MAXNAME)
    {
        fprintf(stderr, "Too many names\n");
        fprintf(stderr, "Increase the value of MAXNAME\n");
        exit(1);
    }
    strcpy(&named[namedp], name);
    namedp += l + 1;
    return (namedp - (l + 1));
}

// The first pass through the input file, where we collect all the
// data we will need to map out the object code
static void readpass1(char *inname)
{
    FILE *input;

    int lineno;
    int type, length, current, ptr, id, value, cad;
    unsigned char buffer[256];

    input = fopen(inname, "r");
    if (input == NULL)
    {
        perror("Can't open input file");
        exit(1);
    }

    lineno = 0;
    cad = 0;

    current = newitem();
    m[current].what = IF_OBJ;
    m[current].size = 0;
    for(;;)
    {
        lineno++;
        readifrecord(input, &type, &length, buffer);
        if (type < 0)   // end of file marker
        {
            fclose(input);
            return;
        }

        switch(type)
        {
        case IF_OBJ:    // plain object code
            // All of these are treated as "object code" for the first passs
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += length;
            cad += length;
            break;

        case IF_DATA:   // dataseg offset word
            // All of these are treated as "object code" for the first passs
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_CONST:  // const seg offset word
            // All of these are treated as "object code" for the first passs
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_DISPLAY:    // display seg offset word
            // All of these are treated as "object code" for the first passs
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_JUMP:   // unconditional jump to label
            current = newitem();
            m[current].what = IF_JUMP;
            m[current].size = 5;                            // assume long to begin with
            m[current].info = (buffer[1] << 8) | buffer[0]; // target label number
            cad += 5;
            break;

        case IF_JCOND:  // cond jump to label JE, JNE, JLE, JL, JGE, JG etc
            current = newitem();
            m[current].what = IF_JCOND;
            m[current].size = 6;                            // assume long to begin with
            // condition code is buffer[0] - not needed on this first pass
            m[current].info = (buffer[2] << 8) | buffer[1]; // target label number
            cad += 6;
            break;

        case IF_CALL:   // call a label
            current = newitem();
            m[current].what = IF_CALL;
            m[current].size = 5;                            // assume long to begin with
            m[current].info = (buffer[1] << 8) | buffer[0]; // target label number
            cad += 5;
            break;

        case IF_LABEL:  // define a label
            current = newitem();
            m[current].what = IF_LABEL;
            m[current].size = 0;                            // labels occupy no space
            m[current].info = (buffer[1] << 8) | buffer[0]; // label number
            break;

        case IF_FIXUP:  // define location for stack fixup instruction
            current = newitem();
            m[current].what = IF_FIXUP;
            m[current].size = 4;    // space will be an ENTER instruction (C8, nnnn, ll)
            m[current].info = 0;    // amount to subtract from the stack will be filled later
            cad += 4;
            ptr = newstack();
            stackfix[ptr].id = (buffer[1] << 8) | buffer[0]; // id number for fixup
            stackfix[ptr].hint = current; // point to this code item
            stackfix[ptr].events = 0;     // assume no events trapped
            stackfix[ptr].trap = 0;       // no label
            buffer[length] = 0;           // make sure we zero terminate the proc name
            stackfix[ptr].namep = newname((char *)&buffer[3]); // debug name
            break;

        case IF_SETFIX:     // stack fixup <location> <amount> <eventmask> <event entry>
            id = (buffer[1] << 8) | buffer[0] ; // id number for fixup
            for (ptr = 0; ptr < ns; ptr++)
            {
                if (stackfix[ptr].id == id)     // found it
                {
                    id = stackfix[ptr].hint;                // point to M record
                    value = (buffer[3] << 8) | buffer[2] ;  // amount to subtract
                    // compiler passes value as a 16 bit negative number, but we're going
                    // to plant an ENTER instruction, so we make it positive...
                    value = - value;
                    value &= 0xffff;
                    m[id].info = value;
                    // now fill in the event stuff...
                    stackfix[ptr].events = (buffer[5] << 8) | buffer[4];
                    stackfix[ptr].trap   = (buffer[7] << 8) | buffer[6];
                    stackfix[ptr].evfrom = (buffer[9] << 8) | buffer[8];
                    break;
                }
            }
            if (ptr == ns)
                fprintf(stderr, "Stack fixup for undefined ID?\n");
            break;

        case IF_REQEXT: // external name spec
            // clear it and count it...
            nspecs += 1;
            if (nspecs == MAXSPECS)
            {
                fprintf(stderr, "Too many %%spec's\n");
                fprintf(stderr, "Increase the value of MAXSPECS\n");
                exit(1);
            }
            specs[nspecs].used = 0;
            specs[nspecs].isdata = 0;   // assume this is an external code name
            current = newitem();
            m[current].what = IF_REQEXT;
            m[current].size = 0;    // definitions/specs occupy no space
            buffer[length] = 0;     // make the name null terminated
            m[current].info = newname((char *)buffer);
            break;

        case IF_REFLABEL:   // label reference as relative address with optional offset
            // add it to list and update current address pointer...
            current = newitem();
            m[current].what = IF_REFLABEL;
            m[current].size = WORDSIZE;                     // label reference == relative address
            m[current].info = (buffer[1] << 8) | buffer[0]; // label number
            // buffer[3],buffer[2] offset is ignored in this pass
            cad += WORDSIZE;
            break;

        case IF_REFEXT:     // external name relative offset code word
            // update our "used" flag
            id = (buffer[1]<<8)|buffer[0];
            specs[id].used = 1;
            // and fall through to treat as a general code word
            // All of these are treated as "object code" for the first pass
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_BSS:    // BSS segment offset code word
            // All of these are treated as "object code" for the first pass
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_COTWORD:    // Constant table word
            if (m[current].what != IF_COTWORD)
            {
                current = newitem();
                m[current].what = IF_COTWORD;
                m[current].size = 0;
            }
            m[current].size += 2;   // NOTE - these are actually halfwords
            break;

        case IF_DATWORD:    // Data segment word
            if (m[current].what != IF_DATWORD)
            {
                current = newitem();
                m[current].what = IF_DATWORD;
                m[current].size = 0;
            }
            m[current].size += 2;   // NOTE - these are actually halfwords
            break;

        case IF_SWTWORD:    // switch table entry - actually a label ID
            if (m[current].what != IF_SWTWORD)
            {
                current = newitem();
                m[current].what = IF_SWTWORD;
                m[current].size = 0;
            }
            m[current].size += 2;   // NOTE - these are actually halfwords
            break;

        case IF_SOURCE: // name of the source file
            // do nothing - not even advance the "current"
            break;

        case IF_DEFEXTCODE: // define a code label that is external
            current = newitem();
            m[current].what = IF_DEFEXTCODE;
            m[current].size = 0;    // definitions/specs occupy no space
            buffer[length] = 0;     // make the name null terminated
            m[current].info = newname((char *)buffer);
            nsymdefs += 1;
            // this is a slightly cheesy way of finding if this is a main program
            if (strcmp((char *)buffer, MAINPROGNAME ) == 0)
                mainprog = 1;	// This is a main program
            break;

        case IF_DEFEXTDATA: // define a data label that is external
            current = newitem();
            m[current].what = IF_DEFEXTDATA;
            m[current].size = 0;    // definitions/specs occupy no space
            buffer[length] = 0;     // make the name null terminated
            m[current].info = newname((char *)buffer);
            nsymdefs += 1;
            break;

        case IF_SWT:    // SWITCH table segment offset code word
            // All of these are treated as "object code" for the first pass
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        case IF_LINE:   // line number info for the debugger
            // note we will recalculate this information on the second pass when
            // jump optimisation will have changed the code addresses, but in the
            // meantime we need to know how many records we will have for the line
            // number section of the object file.
            value = (buffer[1] << 8) | buffer[0] ;   // get the source line number
            newlineno(value, cad);
            break;

        case IF_ABSEXT: // external name relative offset code word
            // update our "used" flag
            id = (buffer[1]<<8) | buffer[0] ;
            specs[id].used = 1;
            specs[id].isdata = 1;   // Hack to say this is a data label
            if (length != WORDSIZE)
                fprintf(stderr, "Oops - length screwup!\n");
            nreloc += 1;
            // All of these are treated as "object code" for the first passs
            if (m[current].what != IF_OBJ)
            {
                current = newitem();
                m[current].what = IF_OBJ;
                m[current].size = 0;
            }
            // we don't bother to remember the code, just how big it is..
            m[current].size += WORDSIZE;
            cad += WORDSIZE;
            break;

        default:
            fprintf(stderr, "Unexpected tag at line#%d - not handled\n",lineno);
            // all other directives don't consume space
            break;
        }
    }
}

// Given a label ID, return the index of the label record
// Return zero if there's no such label
static int findlabel(int id)
{
    int i;

    for (i = 1; i < nl; i++)
        if (labels[i].labelid == id)
            return i;

    return 0;
}

// Reset the label list and then do a pass through the data
// to set up label records.
static void initlabels()
{
    int cad, i, type, ptr, id;

    cad = 0;
    nl = 1;
    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        m[i].address = cad;
        if (type == IF_LABEL)
        {
            id = m[i].info;
            ptr = findlabel(id);    // Pass 2 redefines labels sometimes
            if (ptr == 0)
                ptr = newlabel();
            labels[ptr].labelid = id;
            labels[ptr].address = cad;
        }
        else
        {
            if ((type != IF_COTWORD) && (type != IF_DATWORD) && (type != IF_SWTWORD))
                cad += m[i].size;
        }
    }
}

// Simple routine that tries to "improve" the jumps.
// It returns "true" if it found an improvement.
// Unfortunately we need to iterate because every
// improvement moves all the downstream labels (which
// may allow further improvement), so this routine
// is called more than once.
static int improvejumpsizes()
{
    int i, type, ptr, distance, success;

    success = 0;
    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        if ((type == IF_JUMP) || (type == IF_JCOND))
        {
            if (m[i].size > 2) // not already improved!
            {
                ptr = m[i].info;      // pick up label id
                ptr = findlabel(ptr); // get table index
                distance = labels[ptr].address - (m[i].address + 2);
                if ((-127 < distance) && (distance < 127))	// could this be short?
                {
                    m[i].size = 2; //make it so
                    success = 1;   //and tell the world we've done good
                }
            }
        }
    }
    return success;
}

// cond jump to label JE, JNE, JG, JGE, JL, JLE, JA, JAE, JB, JBE
static unsigned char jcondop[10] = {
    0x74, 0x75, 0x7F, 0x7D, 0x7C, 0x7E, 0x77, 0x73, 0x72, 0x76,
};

static unsigned char jfalseop[10] = {
    0x75, 0x74, 0x7E, 0x7C, 0x7D, 0x7F, 0x76, 0x72, 0x73, 0x77,
};

// Global counter used to plant linker segment size definitions
static int codeseg = 0;
static int dataseg = 0;
static int constseg = 0;
static int bssseg = 0;
static int displayseg = 32;
static int swtabseg = 0;
static int trapseg = 0;

// run through the database adding up the various segment sizes
void computesizes()
{
    int i, type, size;

    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        size = m[i].size;
        switch(type) {
        case IF_OBJ:   // plain object code
            codeseg += size;
            break;

        case IF_DATA:  // dataseg offset word
            codeseg += size;
            break;

        case IF_CONST: // const seg offset word
            codeseg += size;
            break;

        case IF_DISPLAY:    // display offset word
            codeseg += size;
            break;

        case IF_JUMP:   // unconditional jump to label
            codeseg += size;
            break;

        case IF_JCOND:  // cond jump to label JE, JNE, JLE, JL, JGE, JG
            codeseg += size;
            break;

        case IF_CALL:   // call a label
            codeseg += size;
            break;

        case IF_LABEL:  // directive doesn't consume space
            break;

        case IF_FIXUP:  // define location for stack fixup instruction
            codeseg += size;
            break;

        case IF_SETFIX: // directive doesn't consume space
            break;

        case IF_REQEXT: // directive doesn't consume space
            break;

        case IF_REFLABEL:   // label reference as a relative address with optional offset
            codeseg += size;
            break;

        case IF_REFEXT: // external name relative offset code word
            codeseg += size;
            break;

        case IF_BSS:    // BSS seg offset word
            codeseg += size;
            break;

        case IF_COTWORD:    // Constant table word
            constseg += size;
            break;

        case IF_DATWORD:    // Data segment word
            dataseg += size;
            break;

        case IF_SWTWORD:    // switch table entry - actually a label ID
            swtabseg += (size*2);   // so "size" is 16 bit words, but the entries will be 32 bits
            break;

        case IF_SOURCE: // directive doesn't consume space
            break;

        case IF_DEFEXTCODE: // directive doesn't consume space
            break;

        case IF_DEFEXTDATA: // directive doesn't consume space
            break;

        case IF_SWT:        // SWITCH table segment offset code word
            codeseg += size;
            break;

        case IF_LINE:       // directive doesn't consume space
            break;

        case IF_ABSEXT:     // external name relative offset code word
            codeseg += size;
            break;

        default:
            fprintf(stderr, "Unexpected tag - not handled\n");
            // all other directives don't consume space
            break;
        }
    }

    // finally, the trap segment will contain one record for
    // every procedure we've found
    trapseg = ns * 32;
}

// set up the data structures for the ELF file
Elf32_Ehdr  filehead;

// Internal ELF sections, according to the file writer
// zeroth is a pseudo-section containing the file header (for the file writer)
// the actual zeroth section is the NULL section (according to ELF)
#define STRTABSECTION   1   // string table of names        - .strtab
#define CODESECTION     2   // the code itself              - .text
#define CODERELSECTION  3   // the code relocations         - .rel.text
#define CONSTSECTION    4   // the constant data            - .rodata
#define DATASECTION     5   // the writable (own) data      - .data
#define SWTABSECTION    6   // the switch table(s)          - switch
#define SWTABRELSECTION 7   // the switch table relocations - .relswitch
#define TRAPSECTION     8   // the trap table               - trap
#define TRAPRELSECTION  9   // the trap table relocations   - .reltrap
#define TRAPENDSECTION 10   // the trap end marker          - trapend
#define COMMENTSECTION 11   // compiler version             - .comment
#define SYMTABSECTION  12   // the symbol table             - .symtab
#define SHDRSECTION    13   // a pseudo-section containing the section header table

// External ELF sections after we have stripped out empty ones...
int codesection;
int coderelsection;
int constsection;
int datasection;
int swtabsection;
int swtabrelsection;
int trapsection;
int traprelsection;
int trapendsection;
int commentsection;
int symtabsection;

Elf32_Shdr  nullhead;
Elf32_Shdr  strtabhead;
Elf32_Shdr  codehead;
Elf32_Shdr  coderelhead;
Elf32_Shdr  consthead;
Elf32_Shdr  datahead;
Elf32_Shdr  swtabhead;
Elf32_Shdr  swtabrelhead;
Elf32_Shdr  traphead;
Elf32_Shdr  traprelhead;
Elf32_Shdr  trapendhead;
Elf32_Shdr  commenthead;
Elf32_Shdr  symtabhead;

int nelfsections;

void initelf(FILE * output)
{
    int dataoffset, i, trapendseg, nsectsyms;

    if (mainprog != 0)
    {
        nsymdefs = nsymdefs + 2;    // because we will also define the trap table base and end
        trapendseg = TRAPENDSZ;     // segment will be 32 bytes long (same size as a single trap entry
    }
    else
        trapendseg = 0;

    nelfsections = 2; // we always start with null, then strings)
    nsectsyms = 0;    // only "real" sections (like code, const) also have symbols

    // Now we step through in a slightly clunky way and map from logical to real
    // sections, in order to strip empty sections from the output file...

    if (codeseg  != 0)
    {
        codesection = nelfsections;
        coderelsection = nelfsections + 1;
        nsectsyms += 1;
        nelfsections += 2;
    }
    else
    {
        codesection = 0;
        coderelsection = 0;
    }

    if (constseg != 0)
    {
        constsection = nelfsections;
        nelfsections += 1;
        nsectsyms += 1;
    }
    else
        constsection = 0;

    if (dataseg != 0)
    {
        datasection = nelfsections;
        nelfsections += 1;
        nsectsyms += 1;
    }
    else
        datasection = 0;

    if (swtabseg != 0)
    {
        swtabsection = nelfsections;
        swtabrelsection = nelfsections + 1;
        nelfsections += 2;
        nsectsyms += 1;
    }
    else
    {
        swtabsection = 0;
        swtabrelsection = 0;
    }

    if (trapseg != 0)
    {
        trapsection = nelfsections;
        traprelsection = nelfsections + 1;
        nelfsections += 2;
    }
    else
    {
        trapsection = 0;
        traprelsection = 0;
    }

    if (mainprog != 0)
    {
        trapendsection = nelfsections;
        nelfsections += 1;
    }
    else
        trapendsection = 0;

    commentsection = nelfsections++;
    symtabsection = nelfsections++;

    // add all our section names to the string table...
    strtabhead.sh_name = newname(".strtab");
    codehead.sh_name = newname(".text");
    consthead.sh_name = newname(".rodata");
    datahead.sh_name = newname(".data");
    swtabhead.sh_name = newname("switch");
    // In order that we can traverse the trap table at run time we want
    // to ensure that our main trap table base is loaded first in the executable image.
    // The COFF linker groups same-name sections in alphabetical order using the token
    // after a $ symbol (the $ and token are then discarded by the linker).
    // Why letters B, D, F and not A,B,C?  In case we ever want to insert some other
    // sections in the sequence...
    if (mainprog != 0)
        traphead.sh_name = newname("ITRAP$B");
    else
        traphead.sh_name = newname("ITRAP$D");
    trapendhead.sh_name = newname("ITRAP$F");
    commenthead.sh_name = newname(".comment");
    symtabhead.sh_name = newname(".symtab");
    coderelhead.sh_name = newname(".rel.text");
    swtabrelhead.sh_name = newname(".relswitch");
    traprelhead.sh_name = newname(".reltrap");

    // now set up our file writer so that it can work out the section offsets
    dataoffset = sizeof(Elf32_Ehdr);
    setfile(output, dataoffset);
    setsize(STRTABSECTION, namedp);
    setsize(CODESECTION, codeseg);
    setsize(CODERELSECTION, nreloc * sizeof(Elf32_Rel));
    setsize(CONSTSECTION, constseg);
    setsize(DATASECTION, dataseg);
    setsize(SWTABSECTION, swtabseg);
    setsize(SWTABRELSECTION, (swtabseg / 4) * sizeof(Elf32_Rel));
    setsize(TRAPSECTION, trapseg);
    setsize(TRAPRELSECTION, (trapseg / 8) * sizeof(Elf32_Rel));
    setsize(TRAPENDSECTION, trapendseg);
    setsize(COMMENTSECTION, SZVSNCMNT);
    setsize(SYMTABSECTION, (nsymdefs + nspecs + nsectsyms + 2) * sizeof(Elf32_Sym));
    setsize(SHDRSECTION, nelfsections * sizeof(Elf32_Shdr));

    // now we fill in the rest of each of the section headers

    strtabhead.sh_type = SHT_STRTAB;
    strtabhead.sh_flags = 0;
    strtabhead.sh_addr = 0;
    strtabhead.sh_offset = dataoffset;
    strtabhead.sh_size = namedp;
    strtabhead.sh_link = 0;
    strtabhead.sh_info = 0;
    strtabhead.sh_addralign = 1;
    strtabhead.sh_entsize = 0;
    dataoffset += namedp;

    codehead.sh_type = SHT_PROGBITS;
    codehead.sh_flags = SHF_ALLOC|SHF_EXECINSTR;
    codehead.sh_addr = 0;
    codehead.sh_offset = dataoffset;
    codehead.sh_size = codeseg;
    codehead.sh_link = 0;
    codehead.sh_info = 0;
    codehead.sh_addralign = 4;
    codehead.sh_entsize = 0;
    dataoffset += codeseg;

    coderelhead.sh_type = SHT_REL;
    coderelhead.sh_flags = 0;
    coderelhead.sh_addr = 0;
    coderelhead.sh_offset = dataoffset;
    coderelhead.sh_size = nreloc * sizeof(Elf32_Rel);
    coderelhead.sh_link = symtabsection;
    coderelhead.sh_info = codesection;
    coderelhead.sh_addralign = 4;
    coderelhead.sh_entsize = sizeof(Elf32_Rel);
    dataoffset += coderelhead.sh_size;

    consthead.sh_type = SHT_PROGBITS;
    consthead.sh_flags = SHF_ALLOC;
    consthead.sh_addr = 0;
    consthead.sh_offset = dataoffset;
    consthead.sh_size = constseg;
    consthead.sh_link = 0;
    consthead.sh_info = 0;
    consthead.sh_addralign = 4;
    consthead.sh_entsize = 0;
    dataoffset += constseg;

    datahead.sh_type = SHT_PROGBITS;
    datahead.sh_flags = SHF_ALLOC|SHF_WRITE;
    datahead.sh_addr = 0;
    datahead.sh_offset = dataoffset;
    datahead.sh_size = dataseg;
    datahead.sh_link = 0;
    datahead.sh_info = 0;
    datahead.sh_addralign = 4;
    datahead.sh_entsize = 0;
    dataoffset += dataseg;

    swtabhead.sh_type = SHT_PROGBITS;
    swtabhead.sh_flags = SHF_ALLOC;
    swtabhead.sh_addr = 0;
    swtabhead.sh_offset = dataoffset;
    swtabhead.sh_size = swtabseg;
    swtabhead.sh_link = 0;
    swtabhead.sh_info = 0;
    swtabhead.sh_addralign = 4;
    swtabhead.sh_entsize = 0;
    dataoffset += swtabseg;

    swtabrelhead.sh_type = SHT_REL;
    swtabrelhead.sh_flags = 0;
    swtabrelhead.sh_addr = 0;
    swtabrelhead.sh_offset = dataoffset;
    swtabrelhead.sh_size = (swtabseg / 4) * sizeof(Elf32_Rel);
    swtabrelhead.sh_link = symtabsection;
    swtabrelhead.sh_info = swtabsection;
    swtabrelhead.sh_addralign = 4;
    swtabrelhead.sh_entsize = sizeof(Elf32_Rel);
    dataoffset += swtabrelhead.sh_size;

    traphead.sh_type = SHT_PROGBITS;
    traphead.sh_flags = SHF_ALLOC;
    traphead.sh_addr = 0;
    traphead.sh_offset = dataoffset;
    traphead.sh_size = trapseg;
    traphead.sh_link = 0;
    traphead.sh_info = 0;
    traphead.sh_addralign = 32;
    traphead.sh_entsize = 0;
    dataoffset += trapseg;

    traprelhead.sh_type = SHT_REL;
    traprelhead.sh_flags = 0;
    traprelhead.sh_addr = 0;
    traprelhead.sh_offset = dataoffset;
    traprelhead.sh_size = (trapseg / 8) * sizeof(Elf32_Rel);
    traprelhead.sh_link = symtabsection;
    traprelhead.sh_info = trapsection;
    traprelhead.sh_addralign = 4;
    traprelhead.sh_entsize = sizeof(Elf32_Rel);
    dataoffset += traprelhead.sh_size;

    // the end section will be linked after all other trap tables
    trapendhead.sh_type = SHT_PROGBITS;
    trapendhead.sh_flags = SHF_ALLOC;
    trapendhead.sh_addr = 0;
    trapendhead.sh_offset = dataoffset;
    trapendhead.sh_size = TRAPENDSZ;  // make the section size same as a traptable entry
    trapendhead.sh_link = 0;
    trapendhead.sh_info = 0;
    trapendhead.sh_addralign = 32;
    trapendhead.sh_entsize = 0;
    dataoffset += trapendseg;

    commenthead.sh_type = SHT_PROGBITS;
    commenthead.sh_flags = 0;
    commenthead.sh_addr = 0;
    commenthead.sh_offset = dataoffset;
    commenthead.sh_size = SZVSNCMNT;
    commenthead.sh_link = 0;
    commenthead.sh_info = 0;
    commenthead.sh_addralign = 1;
    commenthead.sh_entsize = 0;
    dataoffset += SZVSNCMNT;

    symtabhead.sh_type = SHT_SYMTAB;
    symtabhead.sh_flags = 0;
    symtabhead.sh_addr = 0;
    symtabhead.sh_offset = dataoffset;
    symtabhead.sh_size = (nsymdefs + nspecs + nsectsyms + 2) * sizeof(Elf32_Sym);
    symtabhead.sh_link = STRTABSECTION;
    symtabhead.sh_info = nsectsyms + 2; // one greater than symbol table index of last local symbol
    symtabhead.sh_addralign = 4;
    symtabhead.sh_entsize = sizeof(Elf32_Sym);
    dataoffset += symtabhead.sh_size;

    // Now assemble the main file header
    for(i=0; i < EI_NIDENT; i++)
        filehead.e_ident[i] = elfmagic[i];
    filehead.e_type = ET_REL;
    filehead.e_machine = EM_386;
    filehead.e_version = EV_CURRENT;
    filehead.e_entry = 0;
    filehead.e_phoff = 0;
    filehead.e_shoff = dataoffset;
    filehead.e_flags = 0;
    filehead.e_ehsize = sizeof(Elf32_Ehdr);
    filehead.e_phentsize = 0;
    filehead.e_phnum = 0;
    filehead.e_shentsize = sizeof(Elf32_Shdr);
    filehead.e_shnum = nelfsections;
    filehead.e_shstrndx = STRTABSECTION;

    // write the file header to the start of the file
    fwrite( &filehead, 1, sizeof(Elf32_Ehdr), output);

    // now write each section header to the appropriate part
    writeblock(SHDRSECTION, (unsigned char *)&nullhead,	sizeof(Elf32_Shdr));
    writeblock(SHDRSECTION, (unsigned char *)&strtabhead,	sizeof(Elf32_Shdr));
    if (codesection != 0)
    {
        writeblock(SHDRSECTION, (unsigned char *)&codehead, sizeof(Elf32_Shdr));
        writeblock(SHDRSECTION, (unsigned char *)&coderelhead, sizeof(Elf32_Shdr));
    }
    if (constsection != 0)
        writeblock(SHDRSECTION, (unsigned char *)&consthead, sizeof(Elf32_Shdr));
    if (datasection != 0)
        writeblock(SHDRSECTION, (unsigned char *)&datahead, sizeof(Elf32_Shdr));
    if (swtabsection != 0)
    {
        writeblock(SHDRSECTION, (unsigned char *)&swtabhead, sizeof(Elf32_Shdr));
        writeblock(SHDRSECTION, (unsigned char *)&swtabrelhead, sizeof(Elf32_Shdr));
    }
    if (trapsection != 0)
    {
        writeblock(SHDRSECTION, (unsigned char *)&traphead, sizeof(Elf32_Shdr));
        writeblock(SHDRSECTION, (unsigned char *)&traprelhead, sizeof(Elf32_Shdr));
    }
    if (trapendsection != 0)
        writeblock(SHDRSECTION, (unsigned char *)&trapendhead, sizeof(Elf32_Shdr));
    writeblock(SHDRSECTION, (unsigned char *)&commenthead, sizeof(Elf32_Shdr));
    writeblock(SHDRSECTION, (unsigned char *)&symtabhead,	sizeof(Elf32_Shdr));

    // since it's not really part of anything else useful, we output
    // the linker directive now...
    writeblock(COMMENTSECTION, (unsigned char *)vsncomment, SZVSNCMNT);

    // and similarly we put 0 or 32 bytes of zeroes into the trapend section
    for (i=0; i < trapendseg; i++)
        writebyte(TRAPENDSECTION, 0);
}

//
// when we map the sections into symbols we need a transformation, because
// we miss out any null sections, so they don't get symbols
int codesymbol;
int constsymbol;
int datasymbol;
int swtabsymbol;
int trapsymbol;
int trapendsymbol;
int firstusersymbol;    // the first user symbol table entry (offset by the above junk)

static char auxzeroes[18] = {
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

// Output the dummy symbols in the symbol table for the filename and for each section
static void putsectionsymbols(FILE *output)
{
    Elf32_Sym sym;
    int symbol;

    // first we output the NULL symbol
    sym.st_name = 0;
    sym.st_value = 0;
    sym.st_size = 0;
    sym.st_info = 0;
    sym.st_other = 0;
    sym.st_shndx = 0;
    writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));

    // the first pseudo-symbol is the source filename, which we've stored in path_buffer
    sym.st_name = path_index;
    sym.st_info = (STB_LOCAL << 4) | STT_FILE;
    sym.st_shndx = SHN_ABS;
    writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));


    // set up all the common elements of a section symbol
    sym.st_name  = 0;
    sym.st_value = 0;
    sym.st_size  = 0;
    sym.st_info  = (STB_LOCAL << 4) | STT_SECTION;
    sym.st_other = 0;

    symbol = 2; // the next we will write

    // and now write one for each section...

    // code
    if (codeseg  != 0)
    {
        sym.st_shndx = codesection;
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        codesymbol = symbol;
        symbol += 1;
    }
    // const
    if (constseg != 0)
    {
        sym.st_shndx = constsection;
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        constsymbol = symbol;
        symbol += 1;
    }
    // data
    if (dataseg  != 0)
	{
        sym.st_shndx = datasection;
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        datasymbol = symbol;
        symbol += 1;
    }
    // switch
    if (swtabseg != 0)
    {
        sym.st_shndx = swtabsection;
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        swtabsymbol = symbol;
        symbol += 1;
    }

    firstusersymbol = symbol;   // this is where the program symbol table will start
}

// write the exernal spec table to the symbol table area
static void putexternalspecs(FILE *output)
{
    int i, type, ptr, index;
    Elf32_Sym sym;

    index = 1;  // pass 2 spec's use 1-based IDs

    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        ptr = m[i].info;
        if (type == IF_REQEXT)
        {
            if (specs[index].used)
            {
                sym.st_name = ptr;
                sym.st_value = 0;   // zero (undefined)
                sym.st_size = 0;
                sym.st_info = (STB_GLOBAL << 4) | STT_FUNC;                          // assume this is a function
                if (specs[index].isdata) sym.st_info = (STB_GLOBAL << 4) | STT_FUNC; // No, it's a data label

                sym.st_other = 0;
                sym.st_shndx = 0;   // section zero - external
                writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
            }
            index += 1;
        }
    }
}

// write the external definitions to the symbol table
static void putexternaldefs(FILE *output)
{
    int i, type, ptr;
    Elf32_Sym sym;

    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        ptr = m[i].info;
        if (type == IF_DEFEXTCODE)
        {
            sym.st_name = ptr;
            sym.st_value = m[i].address;    // address of this item
            sym.st_size = 0;                // we don't know these...
            sym.st_info = (STB_GLOBAL << 4) | STT_FUNC;
            sym.st_other = 0;
            sym.st_shndx = codesection;     // section - code
            writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        }
        if (type == IF_DEFEXTDATA)
        {
            sym.st_name = ptr;
            sym.st_value = m[i].address;    // address of this item
            sym.st_size = 0;                // we don't know these...
            sym.st_info = (STB_GLOBAL << 4) | STT_OBJECT;
            sym.st_other = 0;
            sym.st_shndx = datasection;     // section - code
            writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
        }
    }
}

// Write the string table to the output file.  Note that we
// write all of our internal string table, even though not
// all of the entries are used/needed by the linker, or even
// referenced within this object file
static void putstringtable(FILE *output)
{
    writeblock(STRTABSECTION, (unsigned char *)named, namedp);
}

// plant the array of blocks used by %signal to trap
// events in the trap segment.  These blocks contain:
// <StartAddr32><EndAddr32><TrapAddr32><FromAddr32><EventMask16><Name[14]>
static void puttraptable(FILE *output)
{
    int i, j, addr;
    Elf32_Sym sym;
    struct stfix *sp;
    char *namep;

    for (i = 0; i < ns; i++)
    {
        sp = &stackfix[i];
        writew32(TRAPSECTION, sp->start);
        writew32(TRAPSECTION, sp->end);
        // trap and evfrom are actually labels, so we look them up
        j = findlabel(sp->trap);
        writew32(TRAPSECTION, labels[j].address);
        j = findlabel(sp->evfrom);
        writew32(TRAPSECTION, labels[j].address);
        writew16(TRAPSECTION, sp->events);
        namep = &named[sp->namep];
        for(j=0; j<14; j++)
        {
            writebyte(TRAPSECTION, *namep);
            if (*namep) namep++;
        }
        // Of course the four code addresses we've just planted - start/end/entry/from - all
        // need to be relocated by the beginning of the code segment, so we do four
        // relocation records next...
        addr = i * 32;  // address of first words to relocate
        for (j=0; j < 4; j++)
        {
            writew32(TRAPRELSECTION, addr + (j * 4));             // offset in section of word to relocate
            writew32(TRAPRELSECTION, (codesymbol<<8)|R_386_32);   // symbol index for .text
        }
    }

    // if this was the main program file, we define a symbol that
    // corresponds to the base of the trap table, and one at the end.
    if (mainprog != 0)
    {
        sym.st_value = 0;           // first address of this section
        sym.st_size = 0;
        sym.st_info = (STB_GLOBAL << 4) | STT_NOTYPE;
        sym.st_other = 0;

        sym.st_name = trapstart_index;
        sym.st_shndx = trapsection; // section - trap table
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));

        // and again for the trap end
        sym.st_name = trapend_index;
        sym.st_shndx = trapendsection;  // end section ID
        writeblock(SYMTABSECTION, (unsigned char *)&sym, sizeof(Elf32_Sym));
    }
}

// Fill in the line number section of the object file
static void putlinenumbers(FILE *output)
{
    int i;

    i = 0;

    while (i < nlines)
    {
// ABD - ELF strategy not working yet!
//        writew32(LINENOSECTION, lines[i].offset);
//        writew16(LINENOSECTION, lines[i].line);
        i = i + 1;
    }
}

// Main Pass - Reread the input file and write the object code
static void readwrite(FILE *input, FILE *output)
{
    int type, length, current, ptr, id, value, condition, cad, i, segidx;
    int cotp, datap, swtp, offset;
    unsigned char buffer[256];

    current = 0;
    cad = 0;
    cotp = 0;
    datap = 0;
    swtp = 0;
    for(;;)
    {
        readifrecord(input, &type, &length, buffer);
        if (type < 0)
            break;
        switch(type)
        {
        case IF_OBJ:    // plain object code
            if (m[current].what != IF_OBJ)
                current += 1;
            for (i = 0; i < length; i++)
                writebyte(CODESECTION,buffer[i]);
            cad += length;
            break;

        case IF_DATA:   // dataseg offset word
            if (m[current].what != IF_OBJ)
                current += 1;
            for (i=0; i < WORDSIZE; i++)
                writebyte(CODESECTION, buffer[i]);

            segidx = datasymbol;

            writew32(CODERELSECTION, cad);                  // offset in section of word to relocate
            writew32(CODERELSECTION, (segidx<<8)|R_386_32); // symbol for section
            cad += WORDSIZE;
            break;

        case IF_CONST:  // const seg offset word
            if (m[current].what != IF_OBJ)
                current += 1;
            for (i=0; i < WORDSIZE; i++)
                writebyte(CODESECTION, buffer[i]);

            segidx = constsymbol;

            writew32(CODERELSECTION, cad);                  // offset in section of word to relocate
            writew32(CODERELSECTION, (segidx<<8)|R_386_32); // symbol for section
            cad += WORDSIZE;
            break;

        case IF_DISPLAY:    // DISPLAY should have been converted to OBJ
            break;

        case IF_JUMP:       // unconditional jump to label
            current += 1;
            id = buffer[0] | (buffer[1] << 8);  // target label number
            ptr = findlabel(id);
            value = labels[ptr].address;
            if (m[current].size == 2)           // short jump
            {
                writebyte(CODESECTION, 0xEB);
                writebyte(CODESECTION, value - (m[current].address + 2));
                cad += 2;
            }
            else
            {
                writebyte(CODESECTION, 0xE9);   // JMP
                value = value - (m[current].address + 5);
                writew32(CODESECTION, value);
                cad += 5;
            }
            break;

        case IF_JCOND:  // cond jump to label JE, JNE, JLE, JL, JGE, JG
            current += 1;
            condition = buffer[0];
            id = buffer[1] | (buffer[2] << 8);  // target label number
            ptr = findlabel(id);
            value = labels[ptr].address;
            if (m[current].size == 2)           // short jump
            {
                writebyte(CODESECTION, jcondop[condition]);
                writebyte(CODESECTION, value - (m[current].address + 2));
                cad += 2;
            }
            else
            {
                writebyte(CODESECTION, 0x0F);   // prefix
                writebyte(CODESECTION, jcondop[condition] + 0x10);
                value = value - (m[current].address + 6);
                writew32(CODESECTION, value);
                cad += 6;
            }
            break;

        case IF_CALL:   // call a label
            current += 1;
            id = buffer[0] | (buffer[1] << 8);  // target label number
            ptr = findlabel(id);
            value = labels[ptr].address;
            writebyte(CODESECTION, 0xE8);       // CALL
            value = value - (m[current].address + 5);
            writew32(CODESECTION, value);
            cad += 5;
            break;

        case IF_LABEL:  // define a label
            current += 1;
            break;

        case IF_FIXUP:  // define location for stack fixup instruction
            current += 1;
            value = m[current].info;
            // For backward compatibility reasons (mostly because it kept messing
            // me up in development) we will plant suitable code whether this is
            // a "classic" 8086 fixup request - i.e. plant SUB SP,nnnn - or a new
            // style 80286 fixup request to plant ENTER nnnn,level.  We can tell
            // them apart because the classic passes only two parameter bytes.
            if (length == 2)
            {
                writebyte(CODESECTION, 0x81);   // SUB
                writebyte(CODESECTION, 0xEC);   // SP
                writew16(CODESECTION, value);   // Stack displacement
            }
            else
            {
                writebyte(CODESECTION, 0xC8);       // ENTER
                writew16(CODESECTION, value);       // Stack displacement
                writebyte(CODESECTION, buffer[2]);  // level
            }
            // We now update our procedure record with the actual block start location
            id = buffer[0] | (buffer[1] << 8);  // id number for fixup
            for (ptr = 0; ptr < ns; ptr++)
            {
                if (stackfix[ptr].id == id)     // found it
                {
                    stackfix[ptr].start = cad;
                    break;
                }
            }
            cad += 4;
            break;

        case IF_SETFIX: // stack fixup <location> <amount> <eventmask> <event entry>
            // We don't need to do anything in the code stream here, but we use
            // this record to trigger an update of the end point in our block table
            id = buffer[0] | (buffer[1] << 8);  // id number for fixup
            for (ptr = 0; ptr < ns; ptr++)
            {
                if (stackfix[ptr].id == id)     // found it
                {
                    stackfix[ptr].end = cad;
                    break;
                }
            }
            break;

        case IF_REQEXT: // external name spec
            // already taken care of, but need to advance "current"
            current += 1;
            break;

        case IF_REFLABEL:   // plant a label's relative address with optional offset
            current += 1;
            id = buffer[0] | (buffer[1] << 8);      // target label number
            offset = buffer[2] | (buffer[3] << 8);  // offset
            ptr = findlabel(id);
            value = labels[ptr].address;            // relative address of label from code section start
            value = value - (m[current].address + WORDSIZE + offset);   // REFLABEL is WORDSIZE, then extra offset
            writew32(CODESECTION, value);           // relative address + optional offset of label from current location
            cad += 4;
            break;

        case IF_REFEXT: // external name relative offset code word
            if (m[current].what != IF_OBJ) current += 1;

            // ABD - the GNU linker doesn't correctly do Intel PC relative fixups,
            // because it uses the location after the offset, not before it... so,
            // we need to plant an offset of -4 for the call
            writebyte(CODESECTION,0xFC);
            for (i=1; i < WORDSIZE; i++)
                writebyte(CODESECTION,0xFF);
//            writew32(CODESECTION,-4);

            // reference index is in buffer[0,1]
            id = (buffer[1]<<8)|buffer[0];
            id = specs[id].p3index; // remap according to our table
            id += firstusersymbol;  // skip the symbol table entries for the sections

            writew32(CODERELSECTION, cad);                  // offset in section of word to relocate
            writew32(CODERELSECTION, (id<<8)|R_386_PC32);   // symbol index for this reference

            cad += WORDSIZE;
            break;

        case IF_BSS:    // BSS should have been converted to OBJ
            break;

        case IF_COTWORD:    // Constant table word
            if (m[current].what != IF_COTWORD)
            {
                current += 1;
            }
            for (i=0; i < 2; i++)
                writebyte(CONSTSECTION, buffer[i]);
            break;

        case IF_DATWORD:    // Data segment word
            if (m[current].what != IF_DATWORD)
            {
                current += 1;
            }
            for (i=0; i < 2; i++)
                writebyte(DATASECTION, buffer[i]);
            break;

        case IF_SWTWORD:    // switch table entry - actually a label ID
            if (m[current].what != IF_SWTWORD)
            {
                current += 1;
            }
            id = buffer[0] | (buffer[1] << 8);  // target label number
            ptr = findlabel(id);
            value = labels[ptr].address;

            writew32(SWTABSECTION, value);
            // we must also plant a relocation record to make this a code address
            writew32(SWTABRELSECTION, swtp);                     // offset in section of word to relocate
            writew32(SWTABRELSECTION, (codesymbol<<8)|R_386_32); // symbol for section
            swtp += 4;
            break;

        case IF_SOURCE: // name of the source file
            // HACK ALERT - we actually ignore the file name from PASS2 because
            // we've got a nicer library interface and we can get the REAL path
            break;

        case IF_DEFEXTCODE: // define a code label that is external
            // already taken care of, but need to advance "current"
            current += 1;
            break;

        case IF_DEFEXTDATA: // define a data label that is external
            // already taken care of, but need to advance "current"
            current += 1;
            break;

        case IF_SWT:    // SWITCH table segment offset code word
            if (m[current].what != IF_OBJ)
                current += 1;
            for (i=0; i < WORDSIZE; i++)
                writebyte(CODESECTION, buffer[i]);

            segidx = swtabsymbol;

            writew32(CODERELSECTION, cad);                  // offset in section of word to relocate
            writew32(CODERELSECTION, (segidx<<8)|R_386_32); // symbol for section
            cad += WORDSIZE;
            break;

        case IF_LINE:   // line number info for the debugger
            value = buffer[0] | (buffer[1] << 8);
            newlineno(value, cad);
            break;

        case IF_ABSEXT: // external name absolute offset code word (data external)
            if (m[current].what != IF_OBJ) current += 1;
            // Now determine the offset (currently ibj record has it as a 16 bit value == 4 nibbles)
            // the offset is in buffer[0,1] - it should always be a positive number
            // However the Imp Compiler Pass2  doesn't generate a valid IF_ABSEXT record
            // Due to current implementation of Imp Compiler Pass2 -
            // the offset in buffer[0,1] also includes the base index of the underlying symbol
            offset = ((buffer[1]<<8) | buffer[0]);
            id = (buffer[3]<<8) | buffer[2] ;

            offset = offset - id;
            writew32(CODESECTION, offset );

            // id == reference index is in buffer[2,3], which we should already have
            id = specs[id].p3index;                         // remap according to our table
            id += firstusersymbol;                          // skip the symbol table entries for the sections

            writew32(CODERELSECTION, cad);                  // offset in section of word to relocate
            writew32(CODERELSECTION, (id<<8)|R_386_32);     // symbol index for this reference

            // HACK ALERT - our current intermediate code can't distinguish between
            // relative and absolute external relocations, so we can't do external data
            // fixups.... oops!
            cad += WORDSIZE;
            break;

        default:
            fprintf(stderr, "Unexpected tag - not handled\n");
            // all other directives don't consume space
            break;
        }
    }
}

// run through the list of external specs, removing those that
// have not actually been used, and mapping the indexes of those
// that remain to a simple zero-based index
void remapspecs()
{
    int i, index;

    index = 0;  // note, although Pass2 references are 1-based, our map is 0-based
    for (i = 1; i <= nspecs; i++)
    {
        if (specs[i].used)
        {
            specs[i].p3index = index;
            index += 1;
        }
        else
            specs[i].p3index = 0;
    }
    // reassign the specs counter so we know how many we will plant
    nspecs = index;
}

void dumpobjectfile( char *inname, char *outname )
{
    FILE * in;
    FILE * out;
    int i;

    in = fopen(inname, "r");
    out = fopen(outname, "wb");
    if (out == NULL)
    {
        perror("Can't open output file");
        fprintf(stderr, "Usage:  PASS3 <intermediatefile> <objfile>\n");
        exit(1);
    }

    // in order to get a useful debug output, we try to recreate the input
    // file name by assuming that the intermediate files have the same base
    // name and are in the same directory as the source.
#ifdef MSVC
    _fullpath(path_buffer, inname, _MAX_PATH);        // turn it into a full name
#else
    realpath(inname, path_buffer);
#endif
    // Now tweak the file extension from .ibj to imp
    // Only need to alter the last two chars
    // NB char array index starts at 0
    i = strlen(path_buffer);
    path_buffer[i - 2] = 'm';
    path_buffer[i - 1] = 'p';
    path_index = newname(path_buffer);                // and put it in the string table

    // if this is a main program, we need to put the symbols used for finding
    // the trap table into the string table
    if (mainprog != 0)
    {
        trapstart_index = newname(TRAPSTART);
        trapend_index = newname(TRAPEND);
    }

    initelf(out);
    putsectionsymbols(out);

    // reset the line number information
    nlines = 0;
    lastlinead = -1;

    readwrite(in, out);

    // now output the line number records for the debugger
    putlinenumbers(out);
    // Now the xternals
    putexternalspecs(out);
    putexternaldefs(out);
    putstringtable(out);
    // now plant the trap table
    puttraptable(out);

    flushout();

    fclose(in);
    fclose(out);
}

void main(int argc, char **argv)
{
    if (argc < 3)
    {
        fprintf(stderr, "Usage:  PASS3 <intermediatefile> <objfile>\n");
        exit(1);
    }

    readpass1( argv[1] );

    initlabels();
    while (improvejumpsizes())
        initlabels();
    computesizes();

    remapspecs();

    dumpobjectfile( argv[1], argv[2] );

    dataseg = dataseg+constseg+swtabseg+bssseg+displayseg;
    fprintf(stderr, "Code %d bytes  Data %d bytes  Diag %d bytes  Total size %d bytes\n",
        codeseg, dataseg, trapseg, codeseg+dataseg+trapseg);
    fprintf(stderr, "Generated for IMP source file: '%s'\n\n",path_buffer);

    exit(0);
}

