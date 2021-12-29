// IMP Runtime Environment
// Copyright NB Information Limited 2002

#include <stdio.h>
#include <string.h>
#include <errno.h>

// ERRNO is in the MS standard library, but not the GNU one...
#ifndef MSVC
extern int errno;
#endif

int geterrno()
{
    return errno;
}

FILE *getstderr()
{
    return stderr;
}

FILE *getstdin()
{
    return stdin;
}

FILE *getstdout()
{
    return stdout;
}

void fileputreal( double d, FILE *handle)
{
    fprintf( handle,"%e",d);
}
