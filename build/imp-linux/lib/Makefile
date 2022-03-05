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
     implib-typename.o \
     implib-write.o \
     prim-rtl-file.o

all:	libimp77.a

libimp77.a: $(OBJS)
> ar -r libimp77.a $(OBJS)
> ranlib libimp77.a

bootstrap: libimp77.a stdperm.imp
# Ensure all source files have Unix line-endings
> dos2unix stdperm.imp
> dos2unix imprtl-event.imp
> dos2unix imprtl-io.imp
> dos2unix imprtl-main.imp
> dos2unix imprtl-trap.imp
> dos2unix impcore-adef.imp
> dos2unix impcore-aref.imp
> dos2unix impcore-fexp.imp
> dos2unix impcore-iexp.imp
> dos2unix impcore-signal.imp
> dos2unix impcore-strcat.imp
> dos2unix impcore-strcmp.imp
> dos2unix impcore-strcpy.imp
> dos2unix impcore-strjam.imp
> dos2unix impcore-strjcat.imp
> dos2unix impcore-strres.imp
> dos2unix implib-arg.imp
> dos2unix implib-cosine.imp
> dos2unix implib-debug.imp
> dos2unix implib-dispose.imp
> dos2unix implib-env.imp
> dos2unix implib-formatnumber.imp
> dos2unix implib-int2ascii.imp
> dos2unix implib-intpt.imp
> dos2unix implib-itos.imp
> dos2unix implib-new.imp
> dos2unix implib-newline.imp
> dos2unix implib-newlines.imp
> dos2unix implib-print.imp
> dos2unix implib-printstring.imp
> dos2unix implib-read.imp
> dos2unix implib-sine.imp
> dos2unix implib-skipsymbol.imp
> dos2unix implib-space.imp
> dos2unix implib-spaces.imp
> dos2unix implib-substring.imp
> dos2unix implib-tolower.imp
> dos2unix implib-toupper.imp
> dos2unix implib-trim.imp
> dos2unix implib-typename.imp
> dos2unix implib-write.imp
> dos2unix prim-rtl-file.c

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
# Ensure all IMP source files have Unix line-endings
> imp77 -c $<

%.o: %.c
# Ensure all C source files have Unix line-endings
> $(CC) -c $(CCFLAGS) $<
