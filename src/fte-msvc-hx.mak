
# nmake makefile, creates
# - fte.exe  : DPMI 32bit
# - ftew.exe : Win32
#
# Tools used:
# - MS VC++ Toolkit 2003
# - MS Windows SDK include files & libs
# - HX

# To create a full stand-alone DOS binary ( HDPMI32 included ),
# stub loadpero.bin is to be replaced by loadpex.bin.

CC        = \msvc71\bin\cl.exe
LD        = \msvc71\bin\link.exe
RC        = \msvc71\bin\rc.exe
LIB       = \msvc71\bin\lib.exe
INCDIRC   = \msvc71\include
LIBDIRC   = \msvc71\lib

INCDIRW   = \mssdk\include
LIBDIRW   = \mssdk\lib
HXDIRB    = \hx\bin
HXDIRL    = \hx\lib

ODIR =..\build

OPTIMIZE  = /O2 /MT
#OPTIMIZE  = /Zi /Od /MTd

#DEBUG     = -DMSVCDEBUG

OEXT=obj

#APPOPTIONS = -DDEFAULT_INTERNAL_CONFIG

# Use these settings for MSVC 6
#CCFLAGS   = $(OPTIMIZE) -DNT -DNTCONSOLE -DMSVC -DWIN32 -D_CONSOLE -DNO_NEW_CPP_FEATURES -I $(INCDIRC) -I $(INCDIRW) /GX \
#	$(APPOPTIONS) $(DEBUG) \
#	/nologo /W3 /J # /YX

# Use these settings for MSVC 2003
CCFLAGS   = $(OPTIMIZE) -DNT -DNTCONSOLE -DMSVC -DWIN32 -D_CONSOLE -I $(INCDIRC) -I $(INCDIRW) /GX -Fo$(ODIR)\ \
	$(APPOPTIONS) $(DEBUG) \
	/nologo /W3 /J # /YX

LDFLAGS   = /libpath:$(LIBDIRC) /nologo
RCFLAGS   = -i $(INCDIRW)

.SUFFIXES: .cpp .$(OEXT)

!include objs.inc

.cpp{$(ODIR)}.$(OEXT):
	@$(CC) $(CCFLAGS) -c $<

.c{$(ODIR)}.$(OEXT):
	@$(CC) $(CCFLAGS) -c $<

all: $(ODIR) $(ODIR)\fte.exe $(ODIR)\ftew.exe $(ODIR)\fte.cnf 

$(ODIR):
	@mkdir $(ODIR)

$(ODIR)\fte.exe: $(ODIR)\fte.obj $(ODIR)\fte.lib
	@cd $(ODIR)
	@$(LD) @<<
$(LDFLAGS) /out:fte.exe /nod /map:fte.map /merge:.BASE=.data /fixed:no /stub:$(HXDIRB)\loadpero.bin /stack:65536 /filealign:512
fte.obj fte.lib
/libpath:$(HXDIRL) $(HXDIRL)\initw32.obj $(HXDIRL)\getmodh.obj
dkrnl32s.lib duser32s.lib imphlp.lib
libcmt.lib libcpmt.lib oldnames.lib 
<<
	@cd ..\src
	@$(HXDIRB)\patchpe.exe $(ODIR)\fte.exe

$(ODIR)\ftew.exe: $(ODIR)\fte.obj $(ODIR)\fte.lib $(ODIR)\ftewin32.res
	@cd $(ODIR)
	@$(LD) @<<
$(LDFLAGS) /out:ftew.exe /nod /map:ftew.map
fte.obj fte.lib ftewin32.res
/libpath:$(LIBDIRW) kernel32.lib user32.lib
libcmt.lib libcpmt.lib oldnames.lib 
<<
	@cd ..\src

$(ODIR)\cfte.exe: $(CFTE_OBJS:./=..\build\)
	@cd $(ODIR)
	@$(LD) $(LDFLAGS) /libpath:$(LIBDIRW) /out:cfte.exe $(CFTE_OBJS:./=)
	@cd ..\src

$(ODIR)\defcfg.cnf: defcfg.fte $(ODIR)\cfte.exe
	@$(ODIR)\cfte defcfg.fte $(ODIR)\defcfg.cnf

$(ODIR)\defcfg.h: $(ODIR)\defcfg.cnf $(ODIR)\bin2c.exe
	@$(ODIR)\bin2c $(ODIR)\defcfg.cnf >$(ODIR)\defcfg.h

$(ODIR)\fte.cnf: ..\config\* $(ODIR)\cfte.exe
	@$(ODIR)\cfte.exe ..\config\main.fte $(ODIR)\fte.cnf

$(ODIR)\bin2c.exe: bin2c.cpp
	@$(CC) $(CCFLAGS) /Fe$(ODIR)\bin2c.exe bin2c.cpp /link /libpath:$(LIBDIRC) /libpath:$(LIBDIRW)

$(ODIR)\c_config.$(OEXT): $(ODIR)\defcfg.h
	@$(CC) $(CCFLAGS) -I $(ODIR) -c c_config.cpp

$(ODIR)\fte.lib: $(OBJS:./=..\build\) $(NTOBJS:./=..\build\)
	@cd $(ODIR)
	@$(LIB) -nologo @<<
$(OBJS:./=) $(NTOBJS) /OUT:fte.lib
<<
	@cd ..\src

$(ODIR)\ftewin32.res: ftewin32.rc
	@$(RC) $(RCFLAGS) -fo$(ODIR)\ftewin32.res ftewin32.rc

clean:
	@if exist $(ODIR)\*.exe del $(ODIR)\*.exe
	@if exist $(ODIR)\*.lib del $(ODIR)\*.lib
	@if exist $(ODIR)\*.pdb del $(ODIR)\*.pdb
	@if exist $(ODIR)\*.map del $(ODIR)\*.map
	@if exist $(ODIR)\*.obj del $(ODIR)\*.obj
	@if exist $(ODIR)\*.res del $(ODIR)\*.res
	@if exist $(ODIR)\*.cnf del $(ODIR)\*.cnf
	@if exist $(ODIR)\defcfg.h del $(ODIR)\defcfg.h

distro: $(ODIR)\fte.exe $(ODIR)\fte.cnf $(ODIR)\cfte.exe
	@cd $(ODIR)
	@zip ../fte-nt.zip fte.exe fte.cnf cfte.exe
	@cd ..\src

