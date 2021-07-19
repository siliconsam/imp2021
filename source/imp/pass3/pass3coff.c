// IMP Compiler for 80386 - COFF pass 3

// This reads an intermediate object file produced by the
// second pass, performs the jump and stack allocation fixups,
// and writes a standard COFF format object file.  It
// reads the input file twice - once to collect all the jump
// and stack information, and then a second time to actually
// write the object file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include "pass3.h"

// directives that we'd like to pass on to the linker...
static char directive[] = "-defaultlib:LIBI77 ";
#define SZDIRECTIVE		(sizeof(directive)-1)	// we skip the trailing zero

static char path_buffer[_MAX_PATH];	// working areas for file lookup

// So that we can always find the trap table we define two
// special symbols IFF this is a main program block
#define TRAPSTART	"_imptrapbase"
#define	TRAPEND		"_imptrapend"
#define TRAPENDSZ   32

#define MAINPROGNAME "_main"

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
#define MAXNAME 5000
char named[MAXNAME];
int namedp = 0;

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

// set up the data structures for the COFF file
// we are going to have one file header, then five section headers
// for each of code, const, data, switch table and trap data, plus
// a sixth dummy section for the trap table end if we happen to be
// a main program.
// The sections are going to be in that order, each directly following
// the preceding one.  Then there is going to be the relocation list,
// the line-number list, the symbol table, and the string table (for
// names longer than 8 chars).
struct cofffilehdr	filehead;

// Internal coff sections, according to the file writer
#define DIRECTSECTION   1
#define CODESECTION     2
#define CONSTSECTION    3
#define DATASECTION     4
#define SWTABSECTION    5
#define TRAPSECTION     6
#define TRAPENDSECTION  7

// and three pseudo sections for our file write that correspond to the
// three parts of the relocation table (code, switch table, and trap table)
#define CODERELSECTION	8
#define SWTABRELSECTION	9
#define	TRAPRELSECTION	10

// then the pseudo section that is the line number table
#define LINENOSECTION	11

// External coff sections, as they actually appear in the file.  We need
// this because we tidily remove empty sections, so the later ones get
// shifted up, so to speak...
int directsection;
int codesection;
int constsection;
int datasection;
int swtabsection;
int trapsection;
int trapendsection;

struct coffscnhdr   directhead;
struct coffscnhdr   codehead;
struct coffscnhdr   consthead;
struct coffscnhdr   datahead;
struct coffscnhdr   swtabhead;
struct coffscnhdr   traphead;
struct coffscnhdr   trapendhead;

int codereloffset;  // file offset of the relocation records for the code segment
int swtabreloffset; // file offset of the relocation records for the switch table
int trapreloffset;  // file offset of the relocation records for the trap table
int lineoffset;     // file offset for the code source line table
int symtaboffset;   // file offset for the symbol table
int strtaboffset;   // file offset for the string table
int ncoffsections;

void initcoff(FILE * output)
{
    int dataoffset, i, trapendseg, filesyms;

    if (mainprog != 0)
    {
        nsymdefs = nsymdefs + 2;    // because we will also define the trap table base and end
        trapendseg = TRAPENDSZ;     // segment will be 32 bytes long (same size as a single trap entry
    }
    else
        trapendseg = 0;

    ncoffsections = 1;  // how many sections we'll need (always one for directive)
    if (codeseg  != 0) ncoffsections += 1;
    if (constseg != 0) ncoffsections += 1;
    if (dataseg  != 0) ncoffsections += 1;
    if (swtabseg != 0) ncoffsections += 1;
    if (trapseg  != 0) ncoffsections += 1;
    if (mainprog != 0) ncoffsections += 1;  // for the dummy trap table end section

    dataoffset     = SZFILEHDR      + ncoffsections * SZSECHDR; // data starts after all the headers
    codereloffset  = dataoffset     + SZDIRECTIVE + codeseg + dataseg + constseg + swtabseg + trapseg + trapendseg;
    swtabreloffset = codereloffset  + nreloc * SZRELOC;
    trapreloffset  = swtabreloffset + (swtabseg / 4) * SZRELOC;
    lineoffset     = trapreloffset  + (trapseg / 8) * SZRELOC;
    symtaboffset   = lineoffset     + nlines * SZLINENO;
    filesyms       = (strlen(path_buffer) + 36)/18; // little magic to know in advance how many records the .file symbol takes
    strtaboffset   = symtaboffset   + (nsymdefs + nspecs + (ncoffsections*2) + filesyms + 1) * SZSYMENT;

    setfile(output, dataoffset);
    setsize(DIRECTSECTION,  SZDIRECTIVE);
    setsize(CODESECTION,    codeseg);
    setsize(CONSTSECTION,   constseg);
    setsize(DATASECTION,    dataseg);
    setsize(SWTABSECTION,   swtabseg);
    setsize(TRAPSECTION,    trapseg);
    setsize(TRAPENDSECTION, trapendseg);
    setsize(CODERELSECTION, nreloc * SZRELOC);
    setsize(SWTABRELSECTION,(swtabseg / 4) * SZRELOC);
    setsize(TRAPRELSECTION, (trapseg / 8) * SZRELOC);
    setsize(LINENOSECTION,  nlines * SZLINENO);

    // now we manufacture each of the section headers
    strcpy(directhead.s_name, ".drectve");
    directhead.s_paddr   = 0;
    directhead.s_vaddr	 = 0;
    directhead.s_size    = SZDIRECTIVE;
    directhead.s_scnptr  = dataoffset;
    directhead.s_relptr  = 0;
    directhead.s_lnnoptr = 0;
    directhead.s_nreloc  = 0;
    directhead.s_nlnno   = 0;
    directhead.s_flags   = 0x00100a00;  // as used by MS C
    dataoffset += SZDIRECTIVE;

    strcpy(codehead.s_name, ".text");
    codehead.s_paddr    = 0;
    codehead.s_vaddr    = 0;
    codehead.s_size	    = codeseg;
    codehead.s_scnptr   = dataoffset;
    if (nreloc == 0)
        codehead.s_relptr = 0;
    else
        codehead.s_relptr = codereloffset;
    codehead.s_lnnoptr  = lineoffset;
    codehead.s_nreloc   = nreloc;
    codehead.s_nlnno    = nlines;
    codehead.s_flags    = 0x60500020;   // readable executable 16 byte aligned code
    dataoffset += codeseg;

    strcpy(consthead.s_name, ".rdata");
    consthead.s_paddr   = 0;
    consthead.s_vaddr   = 0;
    consthead.s_size    = constseg;
    consthead.s_scnptr  = dataoffset;
    consthead.s_relptr  = 0;
    consthead.s_lnnoptr = 0;
    consthead.s_nreloc  = 0;
    consthead.s_nlnno   = 0;
    consthead.s_flags   = 0x40300040;   // read only 4 byte aligned initialised data
    dataoffset += constseg;

    strcpy(datahead.s_name, ".data");
    datahead.s_paddr    = 0;
    datahead.s_vaddr    = 0;
    datahead.s_size	    = dataseg;
    datahead.s_scnptr   = dataoffset;
    datahead.s_relptr   = 0;
    datahead.s_lnnoptr  = 0;
    datahead.s_nreloc   = 0;
    datahead.s_nlnno    = 0;
    datahead.s_flags    = 0xC0300040;   // read/writable 4 byte aligned initialised data
    dataoffset += dataseg;

    strcpy(swtabhead.s_name, "_SWTAB");
    swtabhead.s_paddr   = 0;
    swtabhead.s_vaddr   = 0;
    swtabhead.s_size    = swtabseg;
    swtabhead.s_scnptr  = dataoffset;
    swtabhead.s_relptr  = swtabreloffset;
    swtabhead.s_lnnoptr = 0;
    swtabhead.s_nreloc  = (swtabseg / 4);   // every 32 bit entry is relocated
    swtabhead.s_nlnno   = 0;
    swtabhead.s_flags   = 0x40300040;       // read only 4 byte aligned initiliased data
    dataoffset += swtabseg;

    // In order that we can traverse the trap table at run time we want
    // to ensure that our main trap table base is loaded first in the executable image.
    // The COFF linker groups same-name sections in alphabetical order using the token
    // after a $ symbol (the $ and token are then discarded by the linker).
    // Why letters B, D, F and not A,B,C?  In case we ever want to insert some other
    // sections in the sequence...
    if (mainprog != 0)
        strcpy(traphead.s_name, "_ITRAP$B");
    else
        strcpy(traphead.s_name, "_ITRAP$D");
    traphead.s_paddr    = 0;
    traphead.s_vaddr    = 0;
    traphead.s_size     = trapseg;
    traphead.s_scnptr   = dataoffset;
    traphead.s_relptr   = trapreloffset;
    traphead.s_lnnoptr  = 0;
    traphead.s_nreloc   = (trapseg / 8);    // every 32 byte entry has 4 addresses to be relocated
    traphead.s_nlnno    = 0;
    traphead.s_flags    = 0x40600040;       // read only 32 byte aligned initialised data
    dataoffset += trapseg;

    // the end section will be linked after all other trap tables
    strcpy(trapendhead.s_name, "_ITRAP$F");
    trapendhead.s_paddr   = 0;
    trapendhead.s_vaddr   = 0;
    trapendhead.s_size    = trapendseg;
    trapendhead.s_scnptr  = dataoffset;
    trapendhead.s_relptr  = 0;          // no relocations - it's just a placeholder
    trapendhead.s_lnnoptr = 0;
    trapendhead.s_nreloc  = 0;
    trapendhead.s_nlnno   = 0;
    trapendhead.s_flags   = 0x40600040; // read only 32 byte aligned initialised data
    dataoffset += trapendseg;

    // Now assemble the main file header
    filehead.f_magic    = 0x014C;
    filehead.f_nscns    = ncoffsections;
    filehead.f_timdat   = (time(NULL) && 0xffffffff);
    filehead.f_symptr   = symtaboffset;
    filehead.f_nsyms    = nsymdefs + nspecs + (ncoffsections*2) + filesyms + 1;
    filehead.f_opthdr   = 0;
    filehead.f_flags    = 0;

    // write the file header first
    fwrite(&filehead, 1, SZFILEHDR, output);

    // we always have a directive section
    fwrite(&directhead, 1, SZSECHDR, output);
    directsection = 1;

    i = 2;  // to count off the sections - directive is #1, so next will be #2

    if (codeseg  != 0)
    {
        fwrite(&codehead, 1, SZSECHDR, output);
        codesection = i++;
    }
    else
        codesection = 0;
    if (constseg != 0)
    {
        fwrite(&consthead, 1, SZSECHDR, output);
        constsection = i++;
    }
    else
        constsection = 0;
    if (dataseg  != 0)
    {
        fwrite(&datahead, 1, SZSECHDR, output);
        datasection = i++;
    }
    else
        datasection = 0;
    if (swtabseg != 0)
    {
        fwrite(&swtabhead, 1, SZSECHDR, output);
        swtabsection = i++;
    }
    else
        swtabsection = 0;
    if (trapseg  != 0)
    {
        fwrite(&traphead, 1, SZSECHDR, output);
        trapsection = i++;
    }
    else
        trapsection = 0;

    if (mainprog != 0)
    {
        fwrite(&trapendhead, 1, SZSECHDR, output);
        trapendsection = i++;
    }
    else
        trapendsection = 0;

    // since it's not really part of anything else useful, we output
    // the linker directive now...
    for (i=0; i < SZDIRECTIVE; i++)
        writebyte(DIRECTSECTION, directive[i]);

    // and similarly we put 16 bytes of zeroes into the trapend section
    for (i=0; i < trapendseg; i++)
        writebyte(TRAPENDSECTION, 0);
}

//
// when we map the sections into symbols we need a transformation, because
// (a) the section table is 1 based but the symbol table is zero based, and
// (b) the aux records we use mean that the symbol table has two entries per section
// (c) we miss out any null sections, so they don't get symbols
// (d) the pseudo-symbol "filename" is output first, so the section symbols are
//     offset by however many records it takes to fit the path name
int directsymbol;
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
    struct coffsyment sym;
    struct coffauxscn aux;
    int sequence, count, length, symbol;
    char * filename;

    fseek(output, symtaboffset, 0);

    // the first pseudo-symbol is the source filename, which we've stored in path_buffer
    filename = path_buffer;
    length = strlen(filename) + 1;  // plus one 'cos we need to zero terminate it (I think)
    count = (length + 17)/18;   // this is how many 18 byte aux records that will take

    sym.n.n_n.n_offset	= 0;    // to make sure we get a clean name
    strcpy(sym.n.n_name, ".file");
    sym.n_scnum     = -2;       // special debug entry
    sym.n_value     = 0;        // no value
    sym.n_type      = 0;        // no type
    sym.n_sclass    = 103;      // a filename
    sym.n_numaux    = count;    // the number of auxilliary records we're using
    fwrite(&sym, 1, SZSYMENT, output);
    symtaboffset += SZSYMENT;

    // now write the filename, padding the last 18 bytes with zeroes
    fwrite(filename, length, 1, output);
    length = count * 18 - length;
    fwrite(auxzeroes, length, 1, output);
    symtaboffset += count * SZSYMENT;

    // The next symbol we write out is the mysterious COMP.ID symbol.
    // Why?  I have no idea, but Microsoft tools like to find this....
    strcpy(sym.n.n_name, "@comp.id");
    sym.n_scnum     = -1;       // special absolute entry
    sym.n_value     = 0x151FE8; // mystery value
    sym.n_type      = 0;        // no type
    sym.n_sclass    = 3;        // static
    sym.n_numaux    = 0;        // no aux record
    fwrite(&sym, 1, SZSYMENT, output);
    symtaboffset += SZSYMENT;

    // OK - the next symbol we will output is going to be...
    symbol = count + 2;

    // set up all the common elements of a section symbol
    sym.n_value     = 0;    // zero (section base)
    sym.n_type      = 0;    // NOT a function
    sym.n_sclass    = 3;    // static
    sym.n_numaux    = 1;    // each has one auxilliary

    aux.x_chsum = 0;        // we don't checksum the sections
    aux.x_secno = 0;
    aux.x_selno = 0;
    aux.x_pad   = 0;

    sequence = 1;

    // directive first
    sym.n.n_n.n_offset  = 0;    // to make sure we get a clean name
    strcpy(sym.n.n_name, ".drectve");
    sym.n_scnum = sequence;
    fwrite(&sym, 1, SZSYMENT, output);
    symtaboffset += SZSYMENT;

    aux.x_scnlen = SZDIRECTIVE;
    aux.x_nreloc = 0;
    aux.x_nlnno = 0;
    fwrite(&aux, 1, SZSYMENT, output);
    symtaboffset += SZSYMENT;

    directsymbol = symbol;
    symbol += 2;

    // code
    if (codeseg  != 0)
    {
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        strcpy(sym.n.n_name, ".text");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = codeseg;
        aux.x_nreloc = nreloc;
        aux.x_nlnno = nlines;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        codesymbol = symbol;
        symbol += 2;
    }
    // const
    if (constseg != 0)
    {
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        strcpy(sym.n.n_name, ".rdata");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = constseg;
        aux.x_nreloc = 0;
        aux.x_nlnno = 0;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        constsymbol = symbol;
        symbol += 2;
    }
    // data
    if (dataseg  != 0)
	{
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        strcpy(sym.n.n_name, ".data");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = dataseg;
        aux.x_nreloc = 0;
        aux.x_nlnno = 0;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        datasymbol = symbol;
        symbol += 2;
    }
    // switch
    if (swtabseg != 0)
    {
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        strcpy(sym.n.n_name, "_SWTAB");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = swtabseg;
        aux.x_nreloc = swtabseg/4;
        aux.x_nlnno = 0;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        swtabsymbol = symbol;
        symbol += 2;
    }
    // trap
    if (trapseg  != 0)
    {
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        if (mainprog != 0)
            strcpy(sym.n.n_name, "_ITRAP$B");
        else
            strcpy(sym.n.n_name, "_ITRAP$D");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = trapseg;
        aux.x_nreloc = trapseg/8;
        aux.x_nlnno = 0;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        trapsymbol = symbol;
        symbol += 2;
    }

    // trap end
    if (mainprog  != 0)
    {
        sym.n.n_n.n_offset = 0; // to make sure we get a clean name
        strcpy(sym.n.n_name, "_ITRAP$F");
        sequence += 1;
        sym.n_scnum = sequence;
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        aux.x_scnlen = 16;
        aux.x_nreloc = 0;
        aux.x_nlnno = 0;
        fwrite(&aux, 1, SZSYMENT, output);
        symtaboffset += SZSYMENT;

        trapendsymbol = symbol;
        symbol += 2;
    }

    firstusersymbol = symbol;   // this is where the program symbol table will start
    if (mainprog != 0)          // plus an extra two for the trap table limits if needed
        firstusersymbol += 2;

}

// write the exernal spec table to the symbol table area
static void putexternalspecs(FILE *output)
{
    int i, type, ptr, index;
    struct coffsyment sym;

    fseek(output, symtaboffset, 0);

    index = 1;  // pass 2 spec's use 1-based IDs

    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        ptr = m[i].info;
        if (type == IF_REQEXT)
        {
            if (specs[index].used)
            {
                sym.n.n_n.n_zeroes = 0;
                sym.n.n_n.n_offset = 0;
                if (strlen(&named[ptr]) <= 8)
                    strcpy(sym.n.n_name, &named[ptr]);
                else
                    sym.n.n_n.n_offset = ptr + 4;
                sym.n_value = 0;    // zero (undefined)
                sym.n_scnum = 0;    // section zero - external
                sym.n_type = 0x20;  // assume this is a function
                if (specs[index].isdata) sym.n_type = 0;    // No, it's a data label
                sym.n_sclass = 2;   // external
                sym.n_numaux = 0;   // no auxilliaries

                fwrite(&sym, 1, SZSYMENT, output);
                symtaboffset += SZSYMENT;
            }
            index += 1;
        }
    }
}

// write the external definitions to the symbol table
static void putexternaldefs(FILE *output)
{
    int i, type, ptr;
    struct coffsyment sym;
    char * name;

    for (i = 0; i < nm; i++)
    {
        type = m[i].what;
        ptr = m[i].info;
        if (type == IF_DEFEXTCODE)
        {
            name = &named[ptr];
            sym.n.n_n.n_zeroes = 0;
            sym.n.n_n.n_offset = 0;
            if (strlen(name) <= 8)
                strcpy(sym.n.n_name, name);
            else
                sym.n.n_n.n_offset = ptr + 4;
            sym.n_value = m[i].address; // address of this item
            sym.n_scnum = codesection;  // section - code
            sym.n_type = 0x20;  // this is a function
            sym.n_sclass = 2;   // external
            sym.n_numaux = 0;   // no auxilliaries
            fwrite(&sym, 1, SZSYMENT, output);
            symtaboffset += SZSYMENT;
        }
        if (type == IF_DEFEXTDATA)
        {
            name = &named[ptr];
            sym.n.n_n.n_zeroes = 0;
            sym.n.n_n.n_offset = 0;
            if (strlen(name) <= 8)
                strcpy(sym.n.n_name, name);
            else
                sym.n.n_n.n_offset = ptr + 4;
            sym.n_value = m[i].address; // address of this item
            sym.n_scnum = datasection;  // section - data
            sym.n_type = 0;             // this is NOT a function
            sym.n_sclass = 2;           // external
            sym.n_numaux = 0;           // no auxilliaries
            fwrite(&sym, 1, SZSYMENT, output);
            symtaboffset += SZSYMENT;
        }
    }
}

// Write the string table to the output file.  Note that we
// write all of our internal string table, even though not
// all of the entries are used/needed by the linker, or even
// referenced within this object file
static void putstringtable(FILE *output)
{
    int count;

    fseek(output, strtaboffset, 0);

    count = namedp + 4;                 // the size (bizarrely) includes the size word
    fwrite(&count, 4, 1, output);       // write the size
    fwrite(named, 1, namedp, output);   // write the string table
}

// plant the array of blocks used by %signal to trap
// events in the trap segment.  These blocks contain:
// <StartAddr32><EndAddr32><TrapAddr32><FromAddr32><EventMask16><Name[14]>
static void puttraptable(FILE *output)
{
    int i, j, addr;
    struct coffsyment sym;
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
            writew32(TRAPRELSECTION, addr + (j * 4));   // offset in section of word to relocate
            writew32(TRAPRELSECTION, codesymbol);       // symbol index for .text
            writew16(TRAPRELSECTION, 6);                // relocate by actual 32 bit address
        }
    }

    // if this was the main program file, we define a symbol that
    // corresponds to the base of the trap table, and one at the end.
    if (mainprog != 0)
    {
        i = newname(TRAPSTART);
        sym.n.n_n.n_zeroes = 0;
        sym.n.n_n.n_offset = i + 4;
        sym.n_value = 0;            // first address of this section
        sym.n_scnum = trapsection;  // this section ID
        sym.n_type = 0;             // this is NOT a function
        sym.n_sclass = 2;           // external definition
        sym.n_numaux = 0;           // no auxilliaries
        fseek(output, symtaboffset, 0);
        fwrite(&sym, 1, SZSYMENT, output);
        // and again for the trap end
        i = newname(TRAPEND);
        sym.n.n_n.n_offset = i + 4;
        sym.n_scnum = trapendsection;   // end section ID
        fwrite(&sym, 1, SZSYMENT, output);
        symtaboffset += (SZSYMENT*2);
    }
}

// Fill in the line number section of the object file
static void putlinenumbers(FILE *output)
{
    int i;

    i = 0;

    while (i < nlines)
    {
        writew32(LINENOSECTION, lines[i].offset);
        writew16(LINENOSECTION, lines[i].line);
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

            writew32(CODERELSECTION, cad);      // offset in section of word to relocate
            writew32(CODERELSECTION, segidx);   // symbol for section
            writew16(CODERELSECTION, 6);        // relocate by actual 32 bit address
            cad += WORDSIZE;
            break;

        case IF_CONST:  // const seg offset word
            if (m[current].what != IF_OBJ)
                current += 1;
            for (i=0; i < WORDSIZE; i++)
                writebyte(CODESECTION, buffer[i]);

            segidx = constsymbol;

            writew32(CODERELSECTION, cad);      // offset in section of word to relocate
            writew32(CODERELSECTION, segidx);   // symbol for section
            writew16(CODERELSECTION, 6);        // relocate by actual 32 bit address
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
            for (i=0; i < WORDSIZE; i++) writebyte(CODESECTION,0);
            // reference index is in buffer[0,1]
            id = (buffer[1]<<8)|buffer[0];
            id = specs[id].p3index;         // remap according to our table
            id += firstusersymbol;          // skip the symbol table entries for the sections

            writew32(CODERELSECTION, cad);  // offset in section of word to relocate
            writew32(CODERELSECTION, id);   // symbol index for this reference
            writew16(CODERELSECTION, 0x14); // relocate by relative 32 bit address

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
            writew32(SWTABRELSECTION, swtp);        // offset in section of word to relocate
            writew32(SWTABRELSECTION, codesymbol);  // symbol for section
            writew16(SWTABRELSECTION, 6);           // relocate by actual 32 bit address
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

            writew32(CODERELSECTION, cad);      // offset in section of word to relocate
            writew32(CODERELSECTION, segidx);   // symbol for section
            writew16(CODERELSECTION, 6);        // relocate by actual 32 bit address
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
            id = specs[id].p3index;         // remap according to our table
            id += firstusersymbol;          // skip the symbol table entries for the sections

            writew32(CODERELSECTION, cad);  // offset in section of word to relocate
            writew32(CODERELSECTION, id);   // symbol index for this reference
            writew16(CODERELSECTION, 6);    // relocate by actual 32 bit address

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
    realpath(inname,path_buffer);
#endif
    // Tweak the path_buffer from xxx,ibj to xxx.imp
    i = strlen(path_buffer);
    path_buffer[i-2] = 'm';
    path_buffer[i-1] = 'p';

    initcoff(out);
    putsectionsymbols(out);

    // reset the line number information
    nlines = 0;
    lastlinead = -1;

    readwrite(in, out);

    // now plant the trap table
    puttraptable(out);
    // now output the line number records for the debugger
    putlinenumbers(out);
    // Now the xternals
    putexternalspecs(out);
    putexternaldefs(out);
    putstringtable(out);

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

