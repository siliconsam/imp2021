"# imp2021"

imp2021 is based on imp77 versions 1.03 and i32-1.03 by Andy Davis et al (University of Edinburgh)

The imp77 versions have been extended by JD McMullin to:-
1) allow a limited set of embedded machine code
2) replace most of the run-time library code implemented in C by an equivalent IMP version.

The remaining run-time C code, is in prim-rtl-file.c (which provides an interface from IMP to the C file I/O routines).

The other remaining C code is for the 2 versions of pass3 of the compiler (pass3coff.c and pass3elf.c).
One version generates PE-COFF output, the other ELF output.
These versions of Pass 3 are written in C for portability reasons.
A new version of Pass 3 for COFF (written in FreePascal) called ibj2coff is available.

This is the current version of a working IMP-77 80386 compiler and library source.
It currently generates 32-bit code only.

Use the "create directories" option in your unzip utility,
and it will put the compiler binaries, source and the library source in subdirectories.

Prerequisites:
1) Microsoft Visual Studio 2019, containing the 32-bit C compiler, 32-bit linker and associated libraries.
   Access to these is via the x86 command shell provided by the Visual Studio Community 2019 suite.
   Do NOT use the x64 command shell

2) The Free Pascal compiler (version 3.2.0 upwards - see www.freepascal.org)
   This is used to build the included tools.

3) To build the compiler pass1 and pass2, you need a binary of each and the imp run-time libraries.
   These two passes (and library run-time) are written in IMP.
   Note that the compiler currently only generates 32-bit code.

4) Pass 3 is written in C for portability reasons and needs the Visual Studio tools.
   An equivalent version of pass3 (written in Free Pascal) called ibj2coff is available.
   ibj2coff.exe can be used instead of the PE-COFF version of pass3 (i.e. pass3coff.exe)

The release folder contains the compiler executables, library and standard include files
The source folder contains the source and scripts to rebuild the compiler.
The source folder includes DOS batch files and Linux Make files for the re-build process.
The Linux version of the IMP77 compiler can be cross-built in Windows.

The following describes the build process for the Windows version of the IMP compiler.

The following hints ass-u-me that the compiler sources and binaries (and a limited documentation set)
have been unpacked to a folder <IMP_INSTALL_HOME>

Post-Installation/Pre-Bootstrap
1)  Amend the batch script <IMP_INSTALL_HOME>\release\bin\setenv.bat
	- to use the correct version of Free Pascal (currently 3.2.2)
	- also amend setenv.bat (in the release and source\scripts folders) to access the Free Pascal compiler (currently 3.2.0)
	- more adventurous souls can try to use other linkers and libraries. However, you are on your own!
2)  Also amend the template batch script <IMP_INSTALL_HOME>\source\imp\scripts\setenv.bat (as above)

**** It is assumed that the initial bootstrap/build will be done on a Windows machine

To run the compiler (assuming that the pre-requisites of Visual Studio and Free Pascal compiler (3.2.0) are met)
1)  get a DOS prompt (for the Visual Studio 2019 x86 version)
2)  cd to <IMP_INSTALL_HOME>\release\bin
3)  run setenv.bat    (Did you amend the setenv script to ensure suitable linker, libraries and are available?)
4)  To run the compiler - execute imp32 against your imp77 source code

	(omit the file extension, as the script assumes an extension of .i or .imp)
        If you want to link multiple object files, use imp32link.bat (omit the .obj extension)
        This script assumes that the first object file is the "program" and is written in IMP77
        It can link sub-modules written in non-IMP source.
	BUT the first module MUST be from an IMP source file.

To build the Windows IMP compiler
1)  get a Visual Studio x86 DOS prompt
2)  cd to release\bin
3)  run setenv.bat
  	(Did you amend the setenv script to ensure suitable linker and libraries are available?)
4)  cd to the source folder
5) run makeall -msvc -Fc -Fs -Fi <target build_dir>
		(this builds the compiler and some pascal utility programs in the specified build directory)
		(-msvc          option needed for the Microsoft C compiler)
		(-Fc -Fs -Fi    options ensure the intermediate .icd,.lst,.ibj,.cod files are retained after compilation)
		(		These files are useful in "debugging" any error in the IMP source(
6)  Did you look to see if there were any errors in the build?

I have found that the Norton anti-virus software does NOT like the pass3.exe of the compiler suite. (Source of pass3.exe is included)
The SONAR program complains that pass3.exe fails the SONAR.Heur.RGC!g23 heuristic test. However, I believe that the test is too severe.
You can exclude the <build_dir> from the SONAR validation (do a web search for "norton sonar false positive" for further information)

To "enhance" the compiler sources.
1)  Backup (or use a source repository system i.e. git)
2)  Alter the source code in <IMP_INSTALL_HOME>\source\imp\... (or <IMP_INSTALL_HOME>\source\tools\...) folders
3)  Build the compiler (by running <IMP_INSTALL_HOME>\source\makeall <NEW_INSTALL_HOME>) (Check for any build errors!)

To test the compiler (ass-u-mes that the build compiler steps have been completed successfully)
1)  get a Visual Studio x86 DOS prompt
2)  cd to <NEW_INSTALL_HOME>\release\bin
3)  run setenv.bat
	(This file is a copy of <IMP_INSTALL_HOME>\source\imp\scripts\setenv.bat which you amended earlier?)
4)  cd to the source folder
5)  run makeall -msvc -Fc -Fs -Fi <new_build_dir>
	(this builds the Windows IMP compiler and some pascal utility programs in the specified build directory)
6)  Did you look to see if there were any errors in the build?
7)  If no errors were found then the new compiler (in <build_dir>) has built itself.
8)  Think up some tests of your own!

Currently the IMP compiler suite is targeted at the Intel 32bit 80386 instruction set and output in either COFF or ELF object file formats.
(Compiler suite (running as a 32-bit program) has been tested against 64-bit versions of:-

	- Windows 10
	- Windows 8.1
	- Centos7 Linux (64-bit) (Linux shell scripts now included)

To cross-build the Linux IMP compiler on a Windows machine.
1)  get a DOS prompt
2)  cd to <IMP_INSTALL_HOME>\release\bin
3)  run setenv.bat
		(Did you amend the setenv script to ensure suitable compilers, linker, libraries are available?)
4)  cd to the source folder
5)  run makelinux <linux_build_dir>
		(this builds a bootstrap version of the compiler+run-time libraries in the specified build directory)
6)  Did you look to see if there were any errors in the build?
7)  If no errors were found then copy the <linux_build_dir> to a Linux machine.
8)  The build steps to bootstrap the IMP compiler are displayed on completion of the makelinux DOS script
9)  Follow those bootstrap instructions on a terminal window on the Linux machine.

When using the takeon program on Linux, ensure that the i77.grammar has Linux line endings (i.e. LF and not CR-LF)
Use the Linux/UNIX utility dos2unix to change the Windows text files (CR-LF line endings) to Linux/UNIX LF line ending.

Possible extensions (not in any particular order of implementation):

1) Add code-generation for 16-bit signed integers (Might need to extend the ibj file format - and changes to pass3)
2) Add code-generation for 16-bit, 32-bit unsigned integers (Might need to extend the ibj file format - and changes to pass3)
3) Extend the compiler suite so that debug symbols are included (This needs pass3 to be upgraded, and possibly pass2)
4) Add line-numbers into the ELF object files)
5) Re-write the associated tools in IMP
6) Eliminate any code-generation code from pass3

	This may require an intermediate program pass2a for various code optimisations (e.g. to improve jump sizes)
	Possibly needing extensions to the ibj format for 8-bit, 16-bit label references.
	Thus pass3 stage would then only generate the PE-COFF or ELF object files.
	(Some command line switches might be needed for pass3 to direct the file generation - e.g. indicate target instruction set)
	Likely need to tweak the code generation/read/manipulation of the IF_JUMP, IF_JCOND, IF_CALL, IF_FIXUP ibj record types

7) Extend the library to access more Windows system/external routines
8) Re-write the prim-rtl-file.c as a corresponding IMP file
9) Re-write the pass3 PE-COFF code in IMP (already written in FreePascal as the ibj2coff.exe program)
10) See if the IMP compiler suite can be modified to use the FreePascal environment (i.e linker and libraries)
11) Write a linker in IMP (to ensure the compiler is not dependent on the Visual Studio tools)
12) Convert the compiler and libraries to generate and use 64-bit addresses
13) Extend the compiler/run-time library to allow dynamic records (i.e. new and dispose) (without using C malloc/free)
14) Extend the IMP language to have objects.
15) Extend the suite to compile another language

		(e.g. Pascal, Java - assuming objects are implemented)
		This requires a new grammar file for input to takeon.imp
		A re-write/extension of pass1.imp
		(and probable alterations to the iCode instruction set + pass2)

16) Target the compiler suite at another instruction set
	
		(e.g. ARM, Java bytecode) - I fancy using a BURG style code-generator!
		This requires a re-write of pass2.imp
		(and probably pass3 - since pass3 includes some code generation)

17) Create a proper iCode assembler in IMP
	
		A FreePascal version is available for 2 way conversion. (icd2assemble.exe and assemble2icd.exe)

18)  Extend the ability to embed machine code inside IMP source.

		pass2 allows a limited set of Intel 386 instructions
		This "machine code" is used by some of the runtime library modules!

19) Extend compiler suite (if not already possible) to create shareable libraries

		i.e. dynamic link libraries - DLLs or Linux shareable libraries

20) Re-write the individual compiler passes to become %externalroutine, then invoke from a "wrapper" IMP program

Enjoy!

	Andy B Davis

	John Derek McMullin
