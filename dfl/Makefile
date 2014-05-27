##
#include config.dmd

TARGET  = dfl.lib dfl_debug.lib

SRCS	= data_object.d enum_format.d debuglog.d package.d all.d base.d application.d \
			internal/dlib.d internal/clib.d internal/utf.d internal/com.d \
			control.d clippingform.d form.d registry.d drawing.d menu.d \
			notifyicon.d commondialog.d filedialog.d folderdialog.d panel.d 
			textbox.d richtextbox.d picturebox.d listbox.d groupbox.d splitter.d \
			usercontrol.d button.d label.d collections.d \
			internal/winapi.d internal/wincom.d \
			event.d socket.d timer.d environment.d messagebox.d tooltip.d combobox.d \
			treeview.d tabcontrol.d colordialog.d listview.d clipboard.d fontdialog.d \
			progressbar.d resources.d statusbar.d imagelist.d toolbar.d 

#OBJS
#RES     = resource.res

####
## http://gcc.gnu.org/onlinedocs/gcc/Invoking-GCC.html
CC      = gcc
CXX     = g++
CFLAGS  = -Wall -O2
CLDFLAGS =
CINCLUDES = -I/usr/local/include
CLIBS     = -L/usr/local/lib -lm

####
## http://dlang.org/dmd-windows.html
DMD     = dmd
DFLAGS = -g
#DFLAGS  = -O -release -inline -noboundscheck
DLDFLAGS = -L/SUBSYSTEM:WINDOWS:5.01
DMDLIBS  = lib/dmd_win32.lib

####
## http://www.digitalmars.com/ctg/sc.html
DMC      = dmc
DMCFLAGS = -HP99 -g -o+none -D_WIN32_WINNT=0x0400 -I$(SETUPHDIR) $(CPPFLAGS)
DMCLIB   = lib
DMCLIBFLAGS = lib -p512 -c -n

##---------------
# $@ : Target name
# $^ : depend Target name
# $< : Target Top Name
# $* : Target name with out suffix name
# $(MACRO:STING1=STRING2) : Replace STRING1 to STRING2
#
all : $(TARGET)

$(TARGET) : $(OBJS)
	$(DMD) $(OBJS) $(RES) $(DMDLIBS) $(DLDFLAGS) -of$@ 

#$(TARGET) : $(SRC)
#	$(DMD) $(SRC) $(RES) $(DMDLIBS) $(DLDFLAGS) -of$@ 

test :
	$(TARGET)

clean :
	del *.obj
	del *.exe
	del *.bak
#	-rm -f $(TARGET) $(OBJS)

.c.obj :
	$(CC) $(CFLAGS) $(INCLUDES) -c $<

.d.obj :
	$(DMD) $(DFLAGS) -c $<

# Depend of header file
# obj : header
# foo.obj : foo.h 

