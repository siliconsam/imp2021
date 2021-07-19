.RECIPEPREFIX = >

BASEDIR = /usr/local

BINDIR = ${BASEDIR}/bin
LIBDIR = ${BASEDIR}/lib
INCDIR = ${BASEDIR}/include

all: assemble2ibj ibj2assemble ibj2compact ibj2coff coff2dump slimibj

# We need to build the various programs
install: assemble2ibj ibj2assemble ibj2compact ibj2coff coff2dump slimibj
> install -t $(BINDIR) assemble2ibj
> install -t $(BINDIR) ibj2assemble
> install -t $(BINDIR) ibj2compact
> install -t $(BINDIR) ibj2coff
> install -t $(BINDIR) coff2dump
> install -t $(BINDIR) slimibj

# do a minimal tidy up of programs and temporary files
clean: #
> rm -f assemble2ibj ibj2assemble ibj2compact ibj2coff coff2dump slimibj
> rm -f *.ppu
> rm -f *.o

# remove the installed tools
clearinstall: #
> rm -f $(BINDIR)/assemble2ibj
> rm -f $(BINDIR)/ibj2assemble
> rm -f $(BINDIR)/ibj2compact
> rm -f $(BINDIR)/ibj2coff
> rm -f $(BINDIR)/coff2dump
> rm -f $(BINDIR)/slimibj

# really scrub away all programs and temporary files
superclean: clean

assemble2ibj:
> fpc -gl assemble2ibj.pas

ibj2assemble:
> fpc -gl ibj2assemble.pas

ibj2compact:
> fpc -gl ibj2compact.pas

ibj2coff:
> fpc -gl ibj2coff.pas

coff2dump:
> fpc -gl coff2dump.pas

slimibj:
> imp77 slimibj.imp


