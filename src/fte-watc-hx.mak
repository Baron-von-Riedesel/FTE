
# create DOS32 binary with Open Watcom v2.0, HX and JWlink.

# if OW Wlink is to be used instead of JWlink:
#  - change "format windows pe hx" to "format windows pe"
#  - apply HX's patchpe tool to the binary after the link step

CC  = \ow20\binnt\wcc386
CPP = \ow20\binnt\wpp386
LD  = jwlink

INCDIR    = -i=\ow20\H -i=\ow20\H\NT
LIBDIR    =

#OPTIMIZE  = /d2
#OPTIMIZE  = /d1 /onatx /oe=40
OPTIMIZE  = /oxa /s

CCFLAGS   = /q /bt=dos /zp4 /5r /fp3 /j $(OPTIMIZE) $(INCDIR) /dDOSP32 /d__32BIT__ /dWATCOM /d__DOS4G__ /d__WATCOM_LFN__
LDFLAGS   = $(LIBDIR)

OBJS = &
./indent.obj &
./e_mark.obj &
./o_modemap.obj &
./c_desktop.obj &
./c_bind.obj &
./c_color.obj &
./c_config.obj &
./c_history.obj &
./c_hilit.obj &
./c_mode.obj &
./e_block.obj &
./e_buffer.obj &
./e_cmds.obj &
./e_cvslog.obj &
./e_svnlog.obj &
./e_redraw.obj &
./e_file.obj &
./e_fold.obj &
./e_trans.obj &
./e_line.obj &
./e_loadsave.obj &
./e_regex.obj &
./e_print.obj &
./e_search.obj &
./e_undo.obj &
./e_tags.obj &
./g_draw.obj &
./g_menu.obj &
./h_ada.obj &
./h_c.obj &
./h_fte.obj &
./h_ipf.obj &
./h_make.obj &
./h_pascal.obj &
./h_perl.obj &
./h_plain.obj &
./h_msg.obj &
./h_rexx.obj &
./h_sh.obj &
./h_tex.obj &
./h_catbs.obj &
./h_simple.obj &
./i_complete.obj &
./i_ascii.obj &
./i_choice.obj &
./i_input.obj &
./i_key.obj &
./i_search.obj &
./i_view.obj &
./i_modelview.obj &
./i_oview.obj &
./o_buflist.obj &
./o_list.obj &
./o_messages.obj &
./o_model.obj &
./o_routine.obj &
./o_buffer.obj &
./o_directory.obj &
./o_cvsbase.obj &
./o_cvs.obj &
./o_cvsdiff.obj &
./o_svnbase.obj &
./o_svn.obj &
./o_svndiff.obj &
./s_files.obj &
./s_direct.obj &
./s_util.obj &
./s_string.obj &
./view.obj &
./gui.obj &
./egui.obj &
./fte.obj &
./commands.obj &
./log.obj

DOSP32OBJS = memicmp.obj &
             port.obj &
             portdos.obj &
             g_text.obj &
             menu_text.obj &
             con_dosx.obj &
             clip_no.obj &
             g_nodlg.obj &
             e_djgpp2.obj

CFTE_OBJS = cfte.obj &
            s_files.obj &
            port.obj &
            memicmp.obj

FTE_OBJS = $OBJS $DOSP32OBJS

.cpp.obj: .AUTODEPEND
	@$(CPP) $[. $(CCFLAGS)

.c.obj: .AUTODEPEND
	@$(CC) $[. $(CCFLAGS)


build: fte.exe

c_config.obj: defcfg.h

bin2c.exe: bin2c.obj
	@$(LD) $(LDFLAGS) @<<
format windows pe hx runtime console
NAME bin2c.exe
FILE bin2c.obj
libpath \OW20\lib386\dos;\OW20\lib386
libfile cstrtdhr.obj, inirmlfn.obj
OP QUIET,STACK=16k,stub=\hx\bin\loadpero.bin
<<

cfte.exe: $(CFTE_OBJS)
	@$(LD) $(LDFLAGS) @<<
format windows pe hx runtime console
NAME cfte.exe
FILE { $(CFTE_OBJS) }
libpath \OW20\lib386\dos;\OW20\lib386
libfile cstrtdhr.obj, inirmlfn.obj
OP QUIET,STACK=16k,stub=\hx\bin\loadpero.bin
<<

defcfg.cnf: defcfg.fte cfte.exe
	@cfte defcfg.fte defcfg.cnf

defcfg.h: defcfg.cnf bin2c.exe
	@bin2c defcfg.cnf >defcfg.h

fte.exe: bin2c.exe cfte.exe defcfg.h $(FTE_OBJS)
	@$(LD) $(LDFLAGS) @<<
format windows pe hx runtime console
NAME fte.exe
FILE { $(FTE_OBJS) }
libpath \OW20\lib386\dos;\OW20\lib386
libfile cstrtdhr.obj, inirmlfn.obj
OP QUIET,MAP,STACK=64k,stub=\hx\bin\loadpero.bin
<<

clean: .SYMBOLIC
	@del *.obj
	@if exist *.err del *.err
	@del bin2c.exe
	@del cfte.exe
	@del fte.exe
	@del defcfg.cnf
	@del defcfg.h

