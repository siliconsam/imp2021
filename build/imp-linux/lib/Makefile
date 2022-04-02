.RECIPEPREFIX = >
CC = gcc -m32
CCFLAGS = -O

# LOOK! Change these three if they don't match your local policies
BASEDIR = /usr/local

BINDIR = ${BASEDIR}/bin
LIBDIR = ${BASEDIR}/lib
INCDIR = ${BASEDIR}/include

OBJS=impcore-arrayutils.o \
     impcore-mathutils.o \
     impcore-signal.o \
     impcore-strutils.o \
     implib-arg.o \
     implib-debug.o \
     implib-env.o \
     implib-heap.o \
     implib-read.o \
     implib-strings.o \
     implib-trig.o \
     imprtl-event.o \
     imprtl-io.o \
     imprtl-main.o \
     imprtl-trap.o \
     prim-rtl-file.o

all:	libimp77.a

libimp77.a: $(OBJS)
> ar -r libimp77.a $(OBJS)
> ranlib libimp77.a

bootstrap: libimp77.a stdperm.imp
# Ensure all source files have Unix line-endings
> dos2unix stdperm.imp
> dos2unix impcore-arrayutils.imp
> dos2unix impcore-mathutils.imp
> dos2unix impcore-signal.imp
> dos2unix impcore-strutils.imp
> dos2unix implib-arg.imp
> dos2unix implib-debug.imp
> dos2unix implib-env.imp
> dos2unix implib-heap.imp
> dos2unix implib-read.imp
> dos2unix implib-strings.imp
> dos2unix implib-trig.imp
> dos2unix imprtl-event.imp
> dos2unix imprtl-io.imp
> dos2unix imprtl-main.imp
> dos2unix imprtl-trap.imp
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
