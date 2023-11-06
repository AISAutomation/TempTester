#--------------------------------------------------------------------------
OS = LINUX
#OS = WINDOWS
#--------------------------------------------------------------------------
DEP = ./.deps
#--------------------------------------------------------------------------
PROG = TempCmd
#--------------------------------------------------------------------------
ifeq ($(OS), LINUX)
TPATH     = linux
TARGET    = $(TPATH)/$(PROG)
CC        = gcc
SIZE      = size
NM        = nm
STRIP     = strip
AFLAGS    = -DOS_$(OS)
CFLAGS    = -Wall -g -O2 -DOS_$(OS)
CFLAGS   += -fno-strict-aliasing
CFLAGS   += -MD -MP -MF $(DEP)/$(@F).d
LDFLAGS  += -L/usr/lib/x86_64-linux-gnu/ -static
LIBS      =  -lusb
INCLUDES  = -I/usr/include/libusb
else ifeq ($(OS), WINDOWS)
TPATH     = windows
TARGET    = $(TPATH)/$(PROG).exe
CC        = gcc.exe     #i586-mingw32msvc-gcc
STRIP     = strip.exe   #i586-mingw32msvc-strip
SIZE      = size.exe    #i586-mingw32msvc-size
NM        = nm.exe      #i586-mingw32msvc-nm
AFLAGS    = -DOS_$(OS)
CFLAGS    = -Wall -g -O2 -DOS_$(OS) -D_WIN32
CFLAGS   += -fno-strict-aliasing
CFLAGS   += -MD -MP -MF $(DEP)/$(@F).d
LIBS      = -lhid -lsetupapi 
INCLUDES  = 
endif

#--------------------------------------------------------------------------
REMOVE = rm -f
#--------------------------------------------------------------------------
COBJ      = hid_$(OS).o \
            main.o
#AOBJ      = data.o
#--------------------------------------------------------------------------
all: $(PROG)
#	cp $(PROG) $(TARGET)
init: 
	mkdir $(DEP)
	mkdir $(BIN)
	
$(PROG): $(COBJ) $(AOBJ)
	$(CC) $(CFLAGS) $(INCLUDES) $(LDFLAGS) $^ $(LIBS) -o $(PROG)
	@$(SIZE) -B $(PROG)
	@$(NM) -n $(PROG) > $(PROG).sym
	@$(STRIP) $(PROG)

$(PROG).exe: $(PROG)
	@cp $(PROG) $(PROG).exe
	
$(COBJ) : %.o: %.c
	$(CC) $(CFLAGS) -c $(INCLUDES) $< -o $@

$(AOBJ) : %.o : %.S
	$(CC) -c $(AFLAGS) $< -o $@

clean:
	$(REMOVE) *.o
	$(REMOVE) $(PROG)
	$(REMOVE) $(PROG).sym
	$(REMOVE) $(PROG).exe
	$(REMOVE) $(TARGET)
	$(REMOVE) $(DEP)/*.d
#--------------------------------------------------------------------------
# Include the dependency files.
include $($(DEP) 2 > /dev/null) $(wildcard $(DEP)/*)
#--------------------------------------------------------------------------
.PHONY : all clean
#--------------------------------------------------------------------------
