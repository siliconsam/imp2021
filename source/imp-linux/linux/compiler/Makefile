.RECIPEPREFIX = >

CC = gcc -m32
CCFLAGS = -O

BASEDIR = /usr/local

BINDIR = ${BASEDIR}/bin
LIBDIR = ${BASEDIR}/lib
INCDIR = ${BASEDIR}/include

# Library explicitly located, rather than searched by linker, so
# that we can bootstrap the compiler before we've installed the
# library
# Also use the possibly "tweaked" local loader script
IMPLIB = ../lib/libimp77.a
LIBOPT = -lm -T ld.i77.script

all: pass1 pass2 pass3

# We need to build pass1,pass2 from their .o files (created by the cross build script make.bat)
# Also build pass3 completely from source
bootstrap: pass3 $(IMPLIB) ld.i77.script
# Just in case convert source files to have Linux line-endings
> dos2unix i77.grammar
> dos2unix pass1.imp
> dos2unix pass2.imp
> dos2unix takeon.imp
# Also, just in case tweak the ld.i77.script
> dos2unix imp77
> dos2unix imp77link
> dos2unix ld.i77.script
# Now build the programs
> $(CC) -o pass1 pass1.o $(IMPLIB) $(LIBOPT)
> $(CC) -o pass2 pass2.o $(IMPLIB) $(LIBOPT)
> $(CC) -o takeon takeon.o $(IMPLIB) $(LIBOPT)
> install -t $(BINDIR) pass1
> install -t $(BINDIR) pass2
> install -t $(BINDIR) pass3elf
> install -t $(BINDIR) takeon
# Also, install the compiler drivers and loader script
> install -t $(BINDIR) imp77
> install -t $(BINDIR) imp77link
> install -t $(BINDIR) ld.i77.script

# We need to build pass1, pass2 and pass3
install: pass1 pass2 pass3
> install -t $(BINDIR) pass1
> install -t $(BINDIR) pass2
> install -t $(BINDIR) pass3elf
> install -t $(BINDIR) takeon
# Also, always install the compiler drivers and loader script
> install -t $(BINDIR) imp77
> install -t $(BINDIR) imp77link
> install -t $(BINDIR) ld.i77.script

# do a minimal tidy up of programs and temporary files
clean: #
> rm -f pass1 pass2 pass3elf takeon
> rm -f i77.tables.imp
> rm -f *.o
> rm -f *.debug

# really scrub away all programs and temporary files
superclean: clean
> rm -f *.cod
> rm -f *.ibj
> rm -f *.icd
> rm -f *.lst

pass1: pass1.o $(IMPLIB)
> $(CC) -o pass1 pass1.o $(IMPLIB) $(LIBOPT)

pass2: pass2.o $(IMPLIB)
> $(CC) -o pass2 pass2.o $(IMPLIB) $(LIBOPT)

pass3: pass3elf

pass3elf: pass3elf.o ifreader.o writebig.o
> $(CC) -o pass3elf pass3elf.o ifreader.o writebig.o

pass1.o: pass1.imp i77.tables.imp
> ${BINDIR}/imp77 -c -Fc -Fs -Fi pass1.imp

i77.tables.imp: takeon i77.grammar $(IMPLIB)
> takeon i77.grammar=i77.tables.imp,i77.par.debug,i77.lex.debug

takeon: takeon.o $(IMPLIB)
> $(CC) -o takeon takeon.o $(IMPLIB) $(LIBOPT)

%.o: %.c
> $(CC) -c $(CCFLAGS) $<

%.o: %.imp
> ${BINDIR}/imp77 -c -Fc -Fs -Fi $<
