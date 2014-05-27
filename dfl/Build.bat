@echo off

rem set path=C:\D\dmd.2.064.2\windows\bin;C:\D\dm\bin;
set path=C:\D\dmd.2.065.0\windows\bin;C:\D\dm\bin;

set dmc_path=C:\D\dm
set dmd_path=C:\D\dmd.2.065.0
set dmd_path_windows=%dmd_path%\windows

set dfl_debug_flags=-debug -g

rem   -version=NO_DRAG_DROP -version=NO_MDI
rem   -debug=SHOW_MESSAGE_INFO -debug=MESSAGE_PAUSE
rem set dfl_flags=%dfl_flags% -debug=SHOW_MESSAGENFO
set _dfl_flags=%dfl_flags% -wi

set dfl_release_flags=-O -inline -release

rem dfl
set dfl_files=data_object.d enum_format.d debuglog.d package.d all.d base.d application.d internal/dlib.d internal/clib.d internal/utf.d internal/com.d control.d clippingform.d form.d registry.d drawing.d menu.d notifyicon.d commondialog.d filedialog.d folderdialog.d panel.d textbox.d richtextbox.d picturebox.d listbox.d groupbox.d splitter.d usercontrol.d button.d label.d collections.d internal/winapi.d internal/wincom.d event.d socket.d timer.d environment.d messagebox.d tooltip.d combobox.d treeview.d tabcontrol.d colordialog.d listview.d   fontdialog.d progressbar.d resources.d statusbar.d imagelist.d toolbar.d 
set dfl_objs=data_object.obj enum_format.obj debuglog.obj package.obj all.obj base.obj application.obj dlib.obj clib.obj utf.obj com.obj control.obj clippingform.obj form.obj registry.obj drawing.obj menu.obj notifyicon.obj commondialog.obj filedialog.obj folderdialog.obj panel.obj textbox.obj richtextbox.obj picturebox.obj listbox.obj groupbox.obj splitter.obj usercontrol.obj button.obj label.obj collections.obj winapi.obj wincom.obj event.obj socket.obj timer.obj environment.obj messagebox.obj tooltip.obj combobox.obj treeview.obj tabcontrol.obj colordialog.obj listview.obj fontdialog.obj progressbar.obj resources.obj statusbar.obj imagelist.obj toolbar.obj 

rem windows libs
set dfl_libs_dfl=user32_dfl.lib shell32_dfl.lib olepro32_dfl.lib
set dfl_libs=%dmc_path%\lib\gdi32.lib %dmc_path%\lib\comctl32.lib %dmc_path%\lib\advapi32.lib %dmc_path%\lib\comdlg32.lib %dmc_path%\lib\ole32.lib %dmc_path%\lib\uuid.lib %dmd_path_windows%\lib\ws2_32.lib %dfl_libs_dfl%

@echo on

@rem   DMC's Basic Utilities required to make these libs.
@rem    %dmc_path%\bin\implib user32_dfl.lib user32_dfl.def
@rem    @if errorlevel 1 goto oops
@rem    %dmc_path%\bin\implib shell32_dfl.lib shell32_dfl.def
@rem    @if errorlevel 1 goto oops
@rem    %dmc_path%\bin\implib olepro32_dfl.lib olepro32_dfl.def
@rem    @if errorlevel 1 goto oops


@echo Compiling debug DFL...
@rem dmd -c %dfl_debug_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
dmd -c %dfl_debug_flags% %_dfl_flags% %dfl_options% %dfl_files%
@if errorlevel 1 goto oops
@echo.
@echo Making debug lib...
lib -c -n -p128 dfl_debug.lib %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops

@echo.
@echo Compiling release DFL...
@rem dmd -c %dfl_release_flags% %_dfl_flags% %dfl_options% -I.. %dfl_files%
dmd -c %dfl_release_flags% %_dfl_flags% %dfl_options%  %dfl_files%
@if errorlevel 1 goto oops
@echo.
@echo Making release lib...
lib -c -n -p128 dfl.lib %dfl_libs% %dfl_objs%
@if errorlevel 1 goto oops

goto end

:oops
@echo.
rem @del *.lib
@echo xXxXxXxXxXxXx==== Failed. ====
@echo.

:end
@echo.
@echo Done.
@rem  This file is used by dfl.exe
@echo dlib=%dlib%>dflcompile.info
@echo dfl_options=%dfl_options%>>dflcompile.info
@echo _dfl_flags=%_dfl_flags%>>dflcompile.info
@echo dfl_debug_flags=%dfl_debug_flags%>>dflcompile.info
@echo dfl_release_flags=%dfl_release_flags%>>dflcompile.info
@%dmd_path_windows%\bin\dmd>>dflcompile.info
@del *.obj
