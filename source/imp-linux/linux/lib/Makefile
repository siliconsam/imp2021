.RECIPEPREFIX = >
CC = gcc -m32
CCFLAGS = -O

# LOOK! Change these three if they don't match your local policies
BASEDIR = /usr/local

BINDIR = ${BASEDIR}/bin
LIBDIR = ${BASEDIR}/lib
INCDIR = ${BASEDIR}/include

OBJS=imprtl-event.o \
     imprtl-io.o \
     imprtl-main.o \
     imprtl-trap.o \
     impcore-adef.o \
     impcore-aref.o \
     impcore-fexp.o \
     impcore-iexp.o \
     impcore-signal.o \
     impcore-strcat.o \
     impcore-strcmp.o \
     impcore-strcpy.o \
     impcore-strjam.o \
     impcore-strjcat.o \
     impcore-strres.o \
     implib-arg.o \
     implib-cosine.o \
     implib-debug.o \
     implib-dispose.o \
     implib-env.o \
     implib-formatnumber.o \
     implib-int2ascii.o \
     implib-intpt.o \
     implib-itos.o \
     implib-new.o \
     implib-newline.o \
     implib-newlines.o \
     implib-print.o \
     implib-printstring.o \
     implib-read.o \
     implib-sine.o \
     implib-skipsymbol.o \
     implib-space.o \
     implib-spaces.o \
     implib-substring.o \
     implib-tolower.o \
     implib-toupper.o \
     implib-trim.o \
     implib-write.o \
     prim-rtl-file.o

all:	libimp77.a

libimp77.a: $(OBJS)
> ar -r libimp77.a $(OBJS)
> ranlib libimp77.a

bootstrap: libimp77.a stdperm.imp
> install -t $(LIBDIR) libimp77.a
> install -t $(INCDIR) stdperm.imp

install: libimp77.a stdperm.imp
> install -t $(LIBDIR) libimp77.a
> install -t $(INCDIR) stdperm.imp

clean: #
> rm -f libimp77.a

superclean: #
> rm -f libimp77.a
> rm -f *.o
> rm -f *.cod
> rm -f *.ibj
> rm -f *.icd
> rm -f *.lst
> rm -f *.obj
> rm -f *.exe

%.o: %.imp
> imp77 -c $<

%.o: %.c
> $(CC) -c $(CCFLAGS) $<
