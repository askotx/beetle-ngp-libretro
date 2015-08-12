DEBUG = 0
FRONTEND_SUPPORTS_RGB565 = 1

MEDNAFEN_DIR := mednafen
MEDNAFEN_LIBRETRO_DIR := mednafen-libretro
NEED_TREMOR = 0

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
endif
endif

# If you have a system with 1GB RAM or more - cache the whole 
# CD for CD-based systems in order to prevent file access delays/hiccups
CACHE_CD = 0

#if no core specified, just pick psx for now

core = ngp

ifeq ($(core), ngp)
   core = ngp
   NEED_BPP = 32
   NEED_BLIP = 1
   NEED_STEREO_SOUND = 1
   CORE_DEFINE := -DWANT_NGP_EMU
   CORE_DIR := $(MEDNAFEN_DIR)/ngp

CORE_SOURCES := $(CORE_DIR)/bios.cpp \
	$(CORE_DIR)/biosHLE.cpp \
	$(CORE_DIR)/dma.cpp \
	$(CORE_DIR)/flash.cpp \
	$(CORE_DIR)/gfx.cpp \
	$(CORE_DIR)/gfx_scanline_colour.cpp \
	$(CORE_DIR)/gfx_scanline_mono.cpp \
	$(CORE_DIR)/interrupt.cpp \
	$(CORE_DIR)/mem.cpp \
	$(CORE_DIR)/neopop.cpp \
	$(CORE_DIR)/rom.cpp \
	$(CORE_DIR)/rtc.cpp \
	$(CORE_DIR)/sound.cpp \
	$(CORE_DIR)/T6W28_Apu.cpp \
	$(CORE_DIR)/Z80_interface.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_disassemble.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_disassemble_extra.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_disassemble_reg.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_disassemble_dst.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_disassemble_src.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_interpret.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_interpret_dst.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_interpret_reg.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_interpret_single.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_interpret_src.cpp \
	$(CORE_DIR)/TLCS-900h/TLCS900h_registers.cpp

HW_CPU_SOURCES += $(MEDNAFEN_DIR)/hw_cpu/z80-fuse/z80.cpp \
				  $(MEDNAFEN_DIR)/hw_cpu/z80-fuse/z80_ops.cpp
TARGET_NAME := mednafen_ngp_libretro
endif

ifeq ($(NEED_BLIP), 1)
RESAMPLER_SOURCES += $(MEDNAFEN_DIR)/sound/Blip_Buffer.cpp
endif

ifeq ($(NEED_STEREO_SOUND), 1)
SOUND_DEFINE := -DWANT_STEREO_SOUND
endif

CORE_INCDIR := -I$(CORE_DIR)

ifeq ($(platform), unix)
   TARGET := $(TARGET_NAME).so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
   ENDIANNESS_DEFINES := -DLSB_FIRST
   ifneq ($(shell uname -p | grep -E '((i.|x)86|amd64)'),)
      IS_X86 = 1
   endif
   LDFLAGS += $(PTHREAD_FLAGS)
   FLAGS += $(PTHREAD_FLAGS) -DHAVE_MKDIR
else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME).dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   ENDIANNESS_DEFINES := -DLSB_FIRST
   LDFLAGS += $(PTHREAD_FLAGS)
   FLAGS += $(PTHREAD_FLAGS) -DHAVE_MKDIR
else ifeq ($(platform), ios)
   TARGET := $(TARGET_NAME)_ios.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   ENDIANNESS_DEFINES := -DLSB_FIRST
   LDFLAGS += $(PTHREAD_FLAGS)
   FLAGS += $(PTHREAD_FLAGS)

   CC = clang -arch armv7 -isysroot $(IOSSDK)
   CXX = clang++ -arch armv7 -isysroot $(IOSSDK)
else ifeq ($(platform), qnx)
   TARGET := $(TARGET_NAME)_qnx.so
   fpic := -fPIC
   SHARED := -lcpp -lm -shared -Wl,--no-undefined -Wl,--version-script=link.T
   ENDIANNESS_DEFINES := -DLSB_FIRST
   #LDFLAGS += $(PTHREAD_FLAGS)
   #FLAGS += $(PTHREAD_FLAGS) -DHAVE_MKDIR
	FLAGS += -DHAVE_MKDIR
	CC = qcc -Vgcc_ntoarmv7le
	CXX = QCC -Vgcc_ntoarmv7le_cpp
	AR = QCC -Vgcc_ntoarmv7le
	FLAGS += -D__BLACKBERRY_QNX__ -marm -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=softfp
else ifeq ($(platform), ps3)
   TARGET := $(TARGET_NAME)_ps3.a
   CC = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
   CXX = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-g++.exe
   AR = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-ar.exe
   ENDIANNESS_DEFINES := -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN
   OLD_GCC := 1
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else ifeq ($(platform), sncps3)
   TARGET := $(TARGET_NAME)_ps3.a
   CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   CXX = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
   ENDIANNESS_DEFINES := -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN
   CXXFLAGS += -Xc+=exceptions
   OLD_GCC := 1
   NO_GCC := 1
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else ifeq ($(platform), psl1ght)
   TARGET := $(TARGET_NAME)_psl1ght.a
   CC = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
   CXX = $(PS3DEV)/ppu/bin/ppu-g++$(EXE_EXT)
   AR = $(PS3DEV)/ppu/bin/ppu-ar$(EXE_EXT)
   ENDIANNESS_DEFINES := -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else ifeq ($(platform), psp1)
	TARGET := $(TARGET_NAME)_psp1.a
	CC = psp-gcc$(EXE_EXT)
	CXX = psp-g++$(EXE_EXT)
	AR = psp-ar$(EXE_EXT)
	ENDIANNESS_DEFINES := -DLSB_FIRST
	FLAGS += -DPSP -G0
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else ifeq ($(platform), xenon)
   TARGET := $(TARGET_NAME)_xenon360.a
   CC = xenon-gcc$(EXE_EXT)
   CXX = xenon-g++$(EXE_EXT)
   AR = xenon-ar$(EXE_EXT)
   ENDIANNESS_DEFINES += -D__LIBXENON__ -m32 -D__ppc__ -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN
   LIBS := $(PTHREAD_FLAGS)
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else ifeq ($(platform), ngc)
   TARGET := $(TARGET_NAME)_ngc.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   CXX = $(DEVKITPPC)/bin/powerpc-eabi-g++$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   ENDIANNESS_DEFINES += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN

   EXTRA_INCLUDES := -I$(DEVKITPRO)/libogc/include
   FLAGS += -DHAVE_MKDIR
   STATIC_LINKING = 1
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_wii.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   CXX = $(DEVKITPPC)/bin/powerpc-eabi-g++$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   ENDIANNESS_DEFINES += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST -DBYTE_ORDER=BIG_ENDIAN

   EXTRA_INCLUDES := -I$(DEVKITPRO)/libogc/include
   FLAGS += -DHAVE_MKDIR
	STATIC_LINKING = 1
else
   TARGET := $(TARGET_NAME).dll
   CC = gcc
   CXX = g++
   IS_X86 = 1
   SHARED := -shared -Wl,--no-undefined -Wl,--version-script=link.T
   LDFLAGS += -static-libgcc -static-libstdc++ -lwinmm
   ENDIANNESS_DEFINES := -DLSB_FIRST
   FLAGS += -DHAVE__MKDIR
endif

ifeq ($(NEED_THREADING), 1)
FLAGS += -DWANT_THREADING
endif

ifeq ($(NEED_CRC32), 1)
FLAGS += -DWANT_CRC32
endif

ifeq ($(NEED_DEINTERLACER), 1)
FLAGS += -DNEED_DEINTERLACER
endif

ifeq ($(NEED_SCSI_CD), 1)
CDROM_SOURCES += $(MEDNAFEN_DIR)/cdrom/scsicd.cpp
endif

ifeq ($(NEED_CD), 1)
CDROM_SOURCES += $(MEDNAFEN_DIR)/cdrom/CDAccess.cpp \
	$(MEDNAFEN_DIR)/cdrom/CDAccess_Image.cpp \
	$(MEDNAFEN_DIR)/cdrom/CDUtility.cpp \
	$(MEDNAFEN_DIR)/cdrom/lec.cpp \
	$(MEDNAFEN_DIR)/cdrom/SimpleFIFO.cpp \
	$(MEDNAFEN_DIR)/cdrom/audioreader.cpp \
	$(MEDNAFEN_DIR)/cdrom/galois.cpp \
	$(MEDNAFEN_DIR)/cdrom/recover-raw.cpp \
	$(MEDNAFEN_DIR)/cdrom/l-ec.cpp \
	$(MEDNAFEN_DIR)/cdrom/cdromif.cpp \
	$(MEDNAFEN_DIR)/cdrom/cd_crc32.cpp
FLAGS += -DNEED_CD
endif

ifeq ($(NEED_TREMOR), 1)
TREMOR_SRC := $(wildcard $(MEDNAFEN_DIR)/tremor/*.c)
FLAGS += -DNEED_TREMOR
endif


MEDNAFEN_SOURCES := $(MEDNAFEN_DIR)/mednafen.cpp \
	$(MEDNAFEN_DIR)/error.cpp \
	$(MEDNAFEN_DIR)/math_ops.cpp \
	$(MEDNAFEN_DIR)/settings.cpp \
	$(MEDNAFEN_DIR)/general.cpp \
	$(MEDNAFEN_DIR)/FileWrapper.cpp \
	$(MEDNAFEN_DIR)/FileStream.cpp \
	$(MEDNAFEN_DIR)/MemoryStream.cpp \
	$(MEDNAFEN_DIR)/Stream.cpp \
	$(MEDNAFEN_DIR)/state.cpp \
	$(MEDNAFEN_DIR)/endian.cpp \
	$(CDROM_SOURCES) \
	$(MEDNAFEN_DIR)/mempatcher.cpp \
	$(MEDNAFEN_DIR)/video/Deinterlacer.cpp \
	$(MEDNAFEN_DIR)/video/surface.cpp \
	$(RESAMPLER_SOURCES) \
	$(MEDNAFEN_DIR)/sound/Stereo_Buffer.cpp \
	$(MEDNAFEN_DIR)/file.cpp \
	$(OKIADPCM_SOURCES) \
	$(MEDNAFEN_DIR)/md5.cpp


LIBRETRO_SOURCES := libretro.cpp stubs.cpp $(THREAD_STUBS)

TRIO_SOURCES += $(MEDNAFEN_DIR)/trio/trio.c \
	$(MEDNAFEN_DIR)/trio/triostr.c

SOURCES_C := 	$(TREMOR_SRC) $(LIBRETRO_SOURCES_C) $(TRIO_SOURCES)

SOURCES := $(LIBRETRO_SOURCES) $(CORE_SOURCES) $(MEDNAFEN_SOURCES) $(HW_CPU_SOURCES) $(HW_MISC_SOURCES) $(HW_SOUND_SOURCES) $(HW_VIDEO_SOURCES)

WARNINGS := -Wall \
	-Wno-sign-compare \
	-Wno-unused-variable \
	-Wno-unused-function \
	-Wno-uninitialized \
	$(NEW_GCC_WARNING_FLAGS) \
	-Wno-strict-aliasing

EXTRA_GCC_FLAGS := -funroll-loops

ifeq ($(NO_GCC),1)
	EXTRA_GCC_FLAGS :=
	WARNINGS :=
endif


OBJECTS := $(SOURCES:.cpp=.o) $(SOURCES_C:.c=.o)

all: $(TARGET)

ifeq ($(DEBUG),0)
   FLAGS += -O2 $(EXTRA_GCC_FLAGS)
else
   FLAGS += -O0 -g
endif

LDFLAGS += $(fpic) $(SHARED)
FLAGS += $(fpic) $(NEW_GCC_FLAGS)
FLAGS += -I. -Imednafen -Imednafen/include -Imednafen/intl -Imednafen/hw_misc -Imednafen/hw_sound -Imednafen/hw_cpu $(CORE_INCDIR) $(EXTRA_CORE_INCDIR)

FLAGS += $(ENDIANNESS_DEFINES) -DSIZEOF_DOUBLE=8 $(WARNINGS) -DMEDNAFEN_VERSION=\"0.9.28\" -DPACKAGE=\"mednafen\" -DMEDNAFEN_VERSION_NUMERIC=928 -DPSS_STYLE=1 -DMPC_FIXED_POINT $(CORE_DEFINE) -DSTDC_HEADERS -D__STDC_LIMIT_MACROS -D__LIBRETRO__ -DNDEBUG -D_LOW_ACCURACY_ $(EXTRA_INCLUDES) $(SOUND_DEFINE) -Dgettext_noop\(a\)=a

ifeq ($(IS_X86), 1)
FLAGS += -DARCH_X86
endif

ifeq ($(CACHE_CD), 1)
FLAGS += -D__LIBRETRO_CACHE_CD__
endif

ifeq ($(NEED_BPP), 16)
FLAGS += -DWANT_16BPP
endif

ifeq ($(FRONTEND_SUPPORTS_RGB565), 1)
FLAGS += -DFRONTEND_SUPPORTS_RGB565
endif

ifeq ($(NEED_BPP), 32)
FLAGS += -DWANT_32BPP
endif


CXXFLAGS += $(FLAGS)
CFLAGS += $(FLAGS)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CXX) -o $@ $^ $(LDFLAGS)
endif

%.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -f $(TARGET) $(OBJECTS)

.PHONY: clean
