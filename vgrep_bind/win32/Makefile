# for Release 
CFLAGS = -A -O
# for Debug
#CFLAGS = -A -g 

PROJ = vgrep.exe
LIBS = tcconio.lib

OBJS =  v.obj   \
        v.res       

$(PROJ):  $(OBJS) 
	  @lcclnk -subsystem console -o lcc\vgrep.exe -map lcc\vgrep.map $(OBJS) $(LIBS)

v.obj: v.c  
v.res: v.rc 


