// WRITEBIG - support for writing object files
// Copyright 2003 NB Information Limited

// Support routines to allow the object file to be written in
// a "scatter gun" way, without thrashing the disk too much.
// The caller can append small numbers of bytes to any section
// of the file, and we will take care of buffering and seeking
// to the right place(s).
#include <stdio.h>
#include "pass3.h"

#define NSECTIONS 20
// section specific data
static int fileptr[NSECTIONS] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
static int size[NSECTIONS] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

// our buffer data structure is designed to scale to allow rather more
// sections that we might sensibly provide buffers for...  We use the
// buffers as a cache of section information

#define NBUFFERS    4
#define BUFSIZE     512

struct secbuff {
    int which;
    int count;
    unsigned char buffer[BUFSIZE];
};

static struct secbuff sb[NBUFFERS];
static int nextbuf = 0;

// Output file information
static int fileoffset = 0;
static FILE *output;

// routine to establish the size of a section.  Must be
// called for each active section before any output is attempted
void setsize(int section, int s)
{
    int i, j;

    size[section] = s;

    // now recompute the offsets
    j = fileoffset;
    for(i=0; i<NSECTIONS; i++)
    {
        fileptr[i] = j;
        j = j + size[i];
    }
}

// routine to describe the output file.  Must be called to
// initialise the output process.
void setfile(FILE * out, int offset)
{
    int i;

    output = out;
    fileoffset = offset;

    // take this opportunity to zap the buffer structures
    for(i=0; i < NBUFFERS; i++)
        sb[i].which = -1;
}

// write the byte B to the appropriate section
void writebyte(int section, unsigned char b)
{
    int i;
    struct secbuff *sp;

    for(i = 0; i < NBUFFERS; i++)
    {
        sp = &sb[i];
        if (sp->which == section)
        {
            sp->buffer[sp->count] = b;
            sp->count += 1;
            if (sp->count == BUFSIZE)   // full
            {
                fseek(output, fileptr[section], 0);
                fwrite(sp->buffer, 1, BUFSIZE, output);
                fileptr[section] += BUFSIZE;
                sp->count = 0;  // clear it for tidiness
                sp->which = -1; // might as well free this one
            }
            return;
        }
    }

    // not found...look for one to re-use
    i = nextbuf;
    for(;;)
    {
        if (sb[i].which == -1)
            break;
        i = i + 1;
        if (i == NBUFFERS)  // wrap if needed
            i = 0;
        if (i == nextbuf)
            break;
    }

    // entry I is the one we'll use.  It may however be occupied

    sp = &sb[i];
    if ((sp->which != -1) && (sp->count != 0))
    {
        fseek(output, fileptr[sp->which], 0);
        fwrite(sp->buffer, 1, sp->count, output);
        fileptr[sp->which] += sp->count;
        sp->count = 0;  // clear it for tidiness
    }
    sp->which = section;    // now it is ours
    sp->buffer[0] = b;
    sp->count = 1;

    // finally, arrange that next time we start with the next entry
    nextbuf += 1;
    if (nextbuf == NBUFFERS)
        nextbuf = 0;
}

// wider version of writebyte
void writew16(int section, int w)
{
    writebyte(section, w & 255 ); w = w >> 8;
    writebyte(section, w & 255 );
}

// wider still
void writew32(int section, int w)
{
    writebyte(section, w & 255 ); w = w >> 8;
    writebyte(section, w & 255 ); w = w >> 8;
    writebyte(section, w & 255 ); w = w >> 8;
    writebyte(section, w & 255 );
}

// and write a whole lump (generally a struct, but we don't care)
void writeblock(int section, unsigned char *buffer, int count)
{
    while(count--)
        writebyte(section, *buffer++);
}

void flushout()
{
    int i;
    struct secbuff *sp;

    for(i = 0; i < NBUFFERS; i++)
    {
        sp = &sb[i];
        if (sp->which >= 0)
        {
            fseek(output, fileptr[sp->which], 0);
            fwrite(sp->buffer, 1, sp->count, output);
            fileptr[sp->which] += sp->count;
            sp->count = 0;  // clear it for tidiness
            sp->which = -1; // mark unused
        }
    }
}
