// Code to read records from the IMP compiler intermediate code

// Record format is:
// <type><length><data>
// For debug purposes, the elements are all written as ascii
// hex characters, where <type> and <length> are each a single
// digit, length refers to the number of bytes (2 chars) of data.

#include <stdio.h>

static int readnibble(FILE *infile)
{
	int c;
	
	for(;;)
	{
		c = fgetc(infile);
		if (c < 0)			// end of file
			return -1;
		if (('0' <= c) && (c <= '9'))
			return c - '0';
		if (('A' <= c) && (c <= 'F'))
			return c + (10 - 'A');
		// ignore everything else
	}
}

void readifrecord(FILE *infile, int *type, int *length, unsigned char *buffer)
{
	int t, l, c1, c2;

	for (;;)
	{
		t = fgetc(infile);
		if ((t < 0)||(('A' <= t) && (t <= 'Z')))
			break;
		// ignore everything else
	}
	t = t - 'A';
	l = (readnibble(infile)<<4)|readnibble(infile);
	if ((t < 0) || (l < 0))	// end of file
	{
		*type = -1;
		return;
	}
	*type = t;
	*length = l;
	while (l > 0)
	{
		c1 = readnibble(infile);
		c2 = readnibble(infile);
		if ((c1 < 0) || (c2< 0))	// end of file
		{
			*type = -1;
			return;
		}
		*buffer++ = (c1<<4) | c2;
		l = l - 1;
	}
}
