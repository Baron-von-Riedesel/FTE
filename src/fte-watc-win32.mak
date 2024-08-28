
# create Win32 binary with Open Watcom v2.0.

# may also be used to create a DOS32 binary with statically linked
# HX's Win32 emulation code. Compared with OW's "true" DOS32 binary,
# this variant has the benefit that it loads way faster when
# large files are to be edited. 

CC       = \ow20\binnt\wcc386
CPP      = \ow20\binnt\wpp386
LD       = \ow20\binnt\wlink
LIB      = \ow20\binnt\wlib.exe
LIBDIRC  = \ow20\lib386
LIBDIRW  = \ow20\lib386\nt

INCDIR    = -i=\ow20\H -i=\ow20\H\NT

!ifndef DOS
DOS = 0
!endif

!if $(DOS)
HXDIR    = \hx
LINKDOS  = jwlink
RELOCS=1
!if $(RELOCS)
STUB=loadpero
DOSLFLAGS=
!else
STUB=loadpxnr
DOSLFLAGS=op norelocs
!endif
!endif

ODIR = ..\build

#OPTIMIZE  = /d2
#OPTIMIZE  = /d1 /onatx /oe=40
OPTIMIZE  = /oxa /s

CCFLAGS   = /q /bt=nt /5r /fp3 /j $(OPTIMIZE) $(INCDIR) /dNT /dNTCONSOLE /dWIN32 /d_CONSOLE /dWATCOM /fo$@
LDFLAGS   = 

OBJS = &
$(ODIR)/indent.obj &
$(ODIR)/e_mark.obj &
$(ODIR)/o_modemap.obj &
$(ODIR)/c_desktop.obj &
$(ODIR)/c_bind.obj &
$(ODIR)/c_color.obj &
$(ODIR)/c_config.obj &
$(ODIR)/c_history.obj &
$(ODIR)/c_hilit.obj &
$(ODIR)/c_mode.obj &
$(ODIR)/e_block.obj &
$(ODIR)/e_buffer.obj &
$(ODIR)/e_cmds.obj &
$(ODIR)/e_cvslog.obj &
$(ODIR)/e_svnlog.obj &
$(ODIR)/e_redraw.obj &
$(ODIR)/e_file.obj &
$(ODIR)/e_fold.obj &
$(ODIR)/e_trans.obj &
$(ODIR)/e_line.obj &
$(ODIR)/e_loadsave.obj &
$(ODIR)/e_regex.obj &
$(ODIR)/e_print.obj &
$(ODIR)/e_search.obj &
$(ODIR)/e_undo.obj &
$(ODIR)/e_tags.obj &
$(ODIR)/g_draw.obj &
$(ODIR)/g_menu.obj &
$(ODIR)/h_ada.obj &
$(ODIR)/h_c.obj &
$(ODIR)/h_fte.obj &
$(ODIR)/h_ipf.obj &
$(ODIR)/h_make.obj &
$(ODIR)/h_pascal.obj &
$(ODIR)/h_perl.obj &
$(ODIR)/h_plain.obj &
$(ODIR)/h_msg.obj &
$(ODIR)/h_rexx.obj &
$(ODIR)/h_sh.obj &
$(ODIR)/h_tex.obj &
$(ODIR)/h_catbs.obj &
$(ODIR)/h_simple.obj &
$(ODIR)/i_complete.obj &
$(ODIR)/i_ascii.obj &
$(ODIR)/i_choice.obj &
$(ODIR)/i_input.obj &
$(ODIR)/i_key.obj &
$(ODIR)/i_search.obj &
$(ODIR)/i_view.obj &
$(ODIR)/i_modelview.obj &
$(ODIR)/i_oview.obj &
$(ODIR)/o_buflist.obj &
$(ODIR)/o_list.obj &
$(ODIR)/o_messages.obj &
$(ODIR)/o_model.obj &
$(ODIR)/o_routine.obj &
$(ODIR)/o_buffer.obj &
$(ODIR)/o_directory.obj &
$(ODIR)/o_cvsbase.obj &
$(ODIR)/o_cvs.obj &
$(ODIR)/o_cvsdiff.obj &
$(ODIR)/o_svnbase.obj &
$(ODIR)/o_svn.obj &
$(ODIR)/o_svndiff.obj &
$(ODIR)/s_files.obj &
$(ODIR)/s_direct.obj &
$(ODIR)/s_util.obj &
$(ODIR)/s_string.obj &
$(ODIR)/view.obj &
$(ODIR)/gui.obj &
$(ODIR)/egui.obj &
$(ODIR)/fte.obj &
$(ODIR)/commands.obj &
$(ODIR)/log.obj

NTOBJS = &
$(ODIR)/g_text.obj &
$(ODIR)/menu_text.obj &
$(ODIR)/con_nt.obj &
$(ODIR)/clip_os2.obj &
$(ODIR)/g_nodlg.obj &
$(ODIR)/e_win32.obj

CFTE_OBJS = &
$(ODIR)/cfte.obj &
$(ODIR)/s_files.obj &
$(ODIR)/memicmp.obj

FTE_OBJS = $(OBJS) $(NTOBJS)

.cpp{$(OUTD)}.obj:
	@$(CPP) $(CCFLAGS) $<

.c{$(OUTD)}.obj:
	@$(CC) $(CCFLAGS) $<


build: $(ODIR) $(ODIR)\fte.exe

$(ODIR):
	@mkdir $(ODIR)

$(ODIR)\fte.exe: $(ODIR)\defcfg.h $(FTE_OBJS)
!if !$(DOS)
	@$(LD) $(LDFLAGS) @<<
format windows pe runtime console
NAME $(ODIR)\fte.exe
FILE { $(FTE_OBJS) }
libpath $(LIBDIRW);$(LIBDIRC)
lib kernel32,user32
OP Q,MAP=$*
<<
!else
	@$(LINKDOS) $(LDFLAGS) @<<
format windows pe hx runtime console
NAME $(ODIR)\fte.exe
FILE { $(FTE_OBJS) }
libpath $(LIBDIRW);$(LIBDIRC);$(HXDIR)\Lib
lib imphlp,dkrnl32s,duser32s
libfile initw3ow.obj, msgbox.obj, getmodh.obj
disable 1030
OP Q,MAP=$*,STUB=$(HXDIR)\Bin\$(STUB).bin $(DOSLFLAGS)
<<
!endif

$(ODIR)\c_config.obj: $(ODIR)\defcfg.h
	@$(CPP) $(CCFLAGS) -i=$(ODIR) c_config.cpp

$(ODIR)\defcfg.h: $(ODIR)\defcfg.cnf $(ODIR)\bin2c.exe
	@$(ODIR)\bin2c $(ODIR)\defcfg.cnf >$(ODIR)\defcfg.h

$(ODIR)\defcfg.cnf: defcfg.fte $(ODIR)\cfte.exe
	@$(ODIR)\cfte defcfg.fte $(ODIR)\defcfg.cnf

$(ODIR)\bin2c.exe: $(ODIR)\bin2c.obj
	@$(LD) $(LDFLAGS) @<<
format windows pe runtime console
NAME $(ODIR)\bin2c.exe
FILE $(ODIR)\bin2c.obj
libpath $(LIBDIRW);$(LIBDIRC)
lib kernel32,user32
OP Q
<<

$(ODIR)\cfte.exe: $(CFTE_OBJS)
	@$(LD) $(LDFLAGS) @<<
format windows pe runtime console
NAME $(ODIR)\cfte.exe
FILE { $(CFTE_OBJS) }
libpath $(LIBDIRW);$(LIBDIRC)
lib kernel32,user32
OP Q
<<

clean: .SYMBOLIC
	@del $(ODIR)\*.obj
	@del $(ODIR)\bin2c.exe
	@del $(ODIR)\cfte.exe
	@del $(ODIR)\fte.exe
	@del $(ODIR)\fte.map
	@del $(ODIR)\defcfg.cnf
	@del $(ODIR)\defcfg.h

