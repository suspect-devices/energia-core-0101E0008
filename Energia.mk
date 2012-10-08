########################################################################
# Energia make file. 
#
# Adaptation (C) 2012 Donald Delmar Davis, Suspect Devices
#
# This is a dirty hack of version 0.9 26.iv.2012 of  M J Oldfield
# Arduino command line tools Makefile
#
# System part (i.e. project independent)
#
# Copyright (C) 2010,2011,2012 Martin Oldfield <m@mjo.tc>, based on
# work that is copyright Nicholas Zambetti, David A. Mellis & Hernando
# Barragan.
# 
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# Adapted from Arduino 0011 Makefile by M J Oldfield
#
# Original Arduino adaptation by mellis, eighthave, oli.keller
#                      
########################################################################
# PATHS
# I assume that unless ENERGIA_DIR is defined that the ENERGIA core is in 
# ../../ENERGIA/cores (it should probably be relative to this file)
# I also assume that unless the MSP430_TOOLS_DIR is defined that the 
# msp430-gcc toolchain is in your path. 
########################################################################
#
# cleanup (the sections around resetting the board and serial monitoring
# need to be gotten rid of.
#
########################################################################
#
# Given a normal sketch directory, all you need to do is to create
# a small Makefile which defines a few things, and then includes this one.
#
# For example:
#
#       ENERGIA_LIBS = Ethernet Ethernet/utility SPI
#       MCU    = atmega2560
#       AVRDUDE_PORT =   /dev/cu.usbmodem12a1
#
#       include /usr/local/share/Energia.mk
#
# Hopefully these will be self-explanatory but in case they're not:
#
#    ENERGIA_LIBS - A list of any libraries used by the sketch (we
#                   assume these are in
#                   $(ENERGIA_DIR)/hardware/libraries 
#
#    MCU    -  the name of the processor
#
# Once this file has been created the typical workflow is just
#
#   $ make install
#
# All of the object files are created in the build-cli subdirectory
# All local sources should be in the current directory and can include:
#  - at most one .pde or .ino file which will be treated as C++ after
#    the standard Energia header and footer have been affixed.
#  - any number of .c, .cpp, .s and .h files
#
# Included libraries are built in the build-cli/libs subdirectory.
#
# Besides make upload you can also
#   make             - no upload
#   make clean       - remove all our dependencies
#   make depends     - update dependencies
#   make install     - connect to the Energia's serial port
#
########################################################################
########################################################################
#
# ENERGIA WITH MSPDEBUG
# make install will attempt to use the mspdebug interface that comes
# with the energia and launchpad
#
########################################################################

########################################################################
# 
# Default TARGET to cwd (ex Daniele Vergini)
ifndef TARGET
TARGET  = $(notdir $(CURDIR))
endif

########################################################################
#
# Energia version number
ifndef ARDUINO_VERSION
ENERGIA_VERSION = 101
endif
ifndef ENERGIA_VERSION
ENERGIA_VERSION = 8
endif

########################################################################
# figure out what system we are on.
# Uname=Darwin
# Uname=Linux
# (defaults to Windows)
# ******************* PATHS ARE HARDCODED *********************
# the firstword works on the macintosh if there is only one
# you can use an external script to guess.
# 

#$

UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
    ifndef AVRDUDE_PORT
        AVRDUDE_PORT=$(firstword $(wildcard /dev/tty.usbmodem*))
    endif
else 
ifeq ($(UNAME),Linux)
    ifndef AVRDUDE_PORT
        AVRDUDE_PORT=/dev/ttyACM0
    endif
else
	UNAME=Windows
    ifndef AVRDUDE_PORT
        AVRDUDE_PORT=COM8:
    endif
endif
endif


########################################################################
# Energia and system paths taylor to your needs..
#

ENERGIA_DIR = /Applications/Energia.app/Contents/Resources/Java/
ifdef ENERGIA_DIR

ifndef MSP430_TOOLS_DIR
MSP430_TOOLS_DIR     = $(ENERGIA_DIR)/hardware/tools/msp430
# The avrdude bundled with ENERGIA can't find it's config
AVRDUDE_CONF	  = $(MSP430_TOOLS_DIR)/etc/avrdude.conf
endif

ifndef MSP430_TOOLS_PATH
MSP430_TOOLS_PATH    = $(MSP430_TOOLS_DIR)/bin
endif

ENERGIA_LIB_PATH  = $(ENERGIA_DIR)/libraries
ENERGIA_CORE_PATH = $(ENERGIA_DIR)/hardware/msp430/cores/msp430
ENERGIA_VAR_PATH  = $(ENERGIA_DIR)/hardware/msp430/variants

else

ENERGIA_LIB_PATH  = ../../msp430/libraries
ENERGIA_CORE_PATH = ../../msp430/cores/energia
ifeq ($(UNAME),Windows)
    AVRDUDE_CONF = ../../energia/avrdude.conf
endif 
ENERGIA_VAR_PATH  = .

#echo $(error "ENERGIA_DIR is not defined")

endif



########################################################################
# Miscellanea
#

ifndef ENERGIA_SKETCHBOOK
ENERGIA_SKETCHBOOK = $(HOME)/sketchbook
endif

ifndef USER_LIB_PATH
USER_LIB_PATH = ../../libraries
endif

# Which variant ? This affects the include path for arduino 1.0 
ifndef VARIANT
VARIANT = launchpad
endif

# processor stuff
ifndef MCU
MCU   = msp430g2553
endif

ifndef F_CPU
F_CPU = 16000000
endif


# Everything gets built in here
OBJDIR  	  = build-cli

########################################################################
# Local sources
#
LOCAL_C_SRCS    = $(wildcard *.c)
LOCAL_CPP_SRCS  = $(wildcard *.cpp)
LOCAL_CC_SRCS   = $(wildcard *.cc)
LOCAL_PDE_SRCS  = $(wildcard *.pde)
LOCAL_INO_SRCS  = $(wildcard *.ino)
LOCAL_AS_SRCS   = $(wildcard *.S)
LOCAL_OBJ_FILES = $(LOCAL_C_SRCS:.c=.o)   $(LOCAL_CPP_SRCS:.cpp=.o) \
		$(LOCAL_CC_SRCS:.cc=.o)   $(LOCAL_PDE_SRCS:.pde=.o) \
		$(LOCAL_INO_SRCS:.ino=.o) $(LOCAL_AS_SRCS:.S=.o)
LOCAL_OBJS      = $(patsubst %,$(OBJDIR)/%,$(LOCAL_OBJ_FILES))

# Dependency files
DEPS            = $(LOCAL_OBJS:.o=.d)

# core sources
ifeq ($(strip $(NO_CORE)),)
ifdef ENERGIA_CORE_PATH
CORE_C_SRCS     = $(wildcard $(ENERGIA_CORE_PATH)/*.c)
CORE_CPP_SRCS   = $(wildcard $(ENERGIA_CORE_PATH)/*.cpp)

ifneq ($(strip $(NO_CORE_MAIN_CPP)),)
CORE_CPP_SRCS := $(filter-out %main.cpp, $(CORE_CPP_SRCS))
endif

CORE_OBJ_FILES  = $(CORE_C_SRCS:.c=.o) $(CORE_CPP_SRCS:.cpp=.o)
CORE_OBJS       = $(patsubst $(ENERGIA_CORE_PATH)/%,  \
			$(OBJDIR)/%,$(CORE_OBJ_FILES))
endif
endif


########################################################################
# Rules for making stuff
#

# The name of the main targets
TARGET_HEX = $(OBJDIR)/$(TARGET).hex
TARGET_ELF = $(OBJDIR)/$(TARGET).elf
TARGETS    = $(OBJDIR)/$(TARGET).*
CORE_LIB   = $(OBJDIR)/libcore.a

# A list of dependencies
DEP_FILE   = $(OBJDIR)/depends.mk

# Names of executables
#
ifdef MSP430_TOOLS_PATH
CC      = $(MSP430_TOOLS_PATH)/msp430-gcc
CXX     = $(MSP430_TOOLS_PATH)/msp430-g++
OBJCOPY = $(MSP430_TOOLS_PATH)/msp430-objcopy
OBJDUMP = $(MSP430_TOOLS_PATH)/msp430-objdump
AR      = $(MSP430_TOOLS_PATH)/msp430-ar
SIZE    = $(MSP430_TOOLS_PATH)/msp430-size
NM      = $(MSP430_TOOLS_PATH)/msp430-nm
MSPDEBUG= $(MSP430_TOOLS_DIR)/mspdebug/mspdebug
else
CC      = msp430-gcc
CXX     = msp430-g++
OBJCOPY = msp430-objcopy
OBJDUMP = msp430-objdump
AR      = msp430-ar
SIZE    = msp430-size
NM      = msp430-nm
MSPDEBUG= mspdebug
endif

REMOVE  = rm -f
MV      = mv -f
CAT     = cat
ECHO    = echo

# General arguments
SYS_LIBS      = $(patsubst %,$(ENERGIA_LIB_PATH)/%,$(ENERGIA_LIBS))
EXTRA_LIBS     = $(patsubst %,$(USER_LIB_PATH)/%,$(USER_LIBS))
SYS_INCLUDES  = $(patsubst %,-I%,$(SYS_LIBS))
USER_INCLUDES = $(patsubst %,-I%,$(EXTRA_LIBS))
LIB_C_SRCS    = $(wildcard $(patsubst %,%/*.c,$(SYS_LIBS)))
LIB_CPP_SRCS  = $(wildcard $(patsubst %,%/*.cpp,$(SYS_LIBS)))
USER_LIB_CPP_SRCS   = $(wildcard $(patsubst %,%/*.cpp,$(EXTRA_LIBS)))
USER_LIB_C_SRCS     = $(wildcard $(patsubst %,%/*.c,$(EXTRA_LIBS)))
LIB_OBJS      = $(patsubst $(ENERGIA_LIB_PATH)/%.c,$(OBJDIR)/libs/%.o,$(LIB_C_SRCS)) \
		$(patsubst $(ENERGIA_LIB_PATH)/%.cpp,$(OBJDIR)/libs/%.o,$(LIB_CPP_SRCS))
USER_LIB_OBJS = $(patsubst $(USER_LIB_PATH)/%.cpp,$(OBJDIR)/libs/%.o,$(USER_LIB_CPP_SRCS)) \
		$(patsubst $(USER_LIB_PATH)/%.c,$(OBJDIR)/libs/%.o,$(USER_LIB_C_SRCS))

CPPFLAGS      = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -DENERGIA=$(ENERGIA_VERSION) -DARDUINO=$(ARDUINO_VERSION) \
			-I. -I$(ENERGIA_CORE_PATH) -I$(ENERGIA_VAR_PATH)/$(VARIANT) \
			$(SYS_INCLUDES) $(USER_INCLUDES) -g -Os -c -Wall \
			-ffunction-sections -fdata-sections 
CFLAGS        = -std=gnu99
CXXFLAGS      = -fno-exceptions
ASFLAGS       = -mmcu=$(MCU) -I. -x assembler-with-cpp 
LDFLAGS       = -mmcu=$(MCU) -Os -Wl,-gc-sections,-u,main $(USER_LDFLAGS)
# Expand and pick the first port
# ARD_PORT      = $(firstword $(wildcard $(AVRDUDE_PORT)))

# Implicit rules for building everything (needed to get everything in
# the right directory)
#
# Rather than mess around with VPATH there are quasi-duplicate rules
# here for building e.g. a system C++ file and a local C++
# file. Besides making things simpler now, this would also make it
# easy to change the build options in future

# library sources
$(OBJDIR)/libs/%.o: $(ENERGIA_LIB_PATH)/%.c
	mkdir -p $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/libs/%.o: $(ENERGIA_LIB_PATH)/%.cpp
	mkdir -p $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/libs/%.o: $(USER_LIB_PATH)/%.cpp
	mkdir -p $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/libs/%.o: $(USER_LIB_PATH)/%.c
	mkdir -p $(dir $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

# normal local sources
# .o rules are for objects, .d for dependency tracking
# there seems to be an awful lot of duplication here!!!
$(OBJDIR)/%.o: %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
#	$(AR) rcs $(OBJDIR)/core.a $@


$(OBJDIR)/%.o: %.cc
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.o: %.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(AR) rcs $(OBJDIR)/core.a $@

$(OBJDIR)/%.o: %.S
	$(CC) -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/%.o: %.s
	$(CC) -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/%.d: %.c
	$(CC) -MM $(CPPFLAGS) $(CFLAGS) $< -MF $@ -MT $(@:.d=.o)
#	$(AR) rcs $(OBJDIR)/core.a $@

$(OBJDIR)/%.d: %.cc
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.cpp
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)
#	$(AR) rcs $(OBJDIR)/core.a $@

$(OBJDIR)/%.d: %.S
	$(CC) -MM $(CPPFLAGS) $(ASFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.s
	$(CC) -MM $(CPPFLAGS) $(ASFLAGS) $< -MF $@ -MT $(@:.d=.o)

# the pde -> cpp -> o file
$(OBJDIR)/%.cpp: %.pde
	$(ECHO) '#include "WProgram.h"' > $@
	$(CAT)  $< >> $@

# the ino -> cpp -> o file
$(OBJDIR)/%.cpp: %.ino
	$(ECHO) '#include <Energia.h>' > $@
	$(CAT)  $< >> $@

$(OBJDIR)/%.o: $(OBJDIR)/%.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.d: $(OBJDIR)/%.cpp
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)

# core files
$(OBJDIR)/%.o: $(ENERGIA_CORE_PATH)/%.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(AR) rcs $(OBJDIR)/core.a $@

$(OBJDIR)/%.o: $(ENERGIA_CORE_PATH)/%.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(AR) rcs $(OBJDIR)/core.a $@

# various object conversions
$(OBJDIR)/%.hex: $(OBJDIR)/%.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

$(OBJDIR)/%.eep: $(OBJDIR)/%.elf
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
		--change-section-lma .eeprom=0 -O ihex $< $@

$(OBJDIR)/%.lss: $(OBJDIR)/%.elf
	$(OBJDUMP) -h -S $< > $@

$(OBJDIR)/%.sym: $(OBJDIR)/%.elf
	$(NM) -n $< > $@

########################################################################
#
# MSPDEBUG STUFF
#


MSPDEBUG_OPTS = rf2500 --force-reset


########################################################################
#
# Explicit targets start here
#

all: 		$(OBJDIR) $(TARGET_HEX)

$(OBJDIR):
		mkdir $(OBJDIR)

$(TARGET_ELF): 	$(LOCAL_OBJS) $(CORE_LIB) $(OTHER_OBJS)
		$(CC) $(LDFLAGS) -o $@ $(LOCAL_OBJS) $(CORE_LIB) $(OTHER_OBJS) -lc -lm
		$(CC)  -Os -Wl,-gc-sections,-u,main -mmcu=msp430g2553 -o $@ $(LOCAL_OBJS) $(OBJDIR)/core.a $(OTHER_OBJS) -lc -lm

$(CORE_LIB):	$(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)
		$(AR) rcs $@ $(CORE_OBJS) $(LIB_OBJS) $(USER_LIB_OBJS)

$(DEP_FILE):	$(OBJDIR) $(DEPS)
		cat $(DEPS) > $(DEP_FILE)

install: upload

program: upload

upload:	$(TARGET_HEX)
		echo prog $(TARGET_HEX)| $(MSPDEBUG) $(MSPDEBUG_OPTS)

clean:
		$(REMOVE) $(LOCAL_OBJS) $(CORE_OBJS) $(LIB_OBJS) $(CORE_LIB) $(TARGETS) $(DEP_FILE) $(DEPS) $(USER_LIB_OBJS)

depends:	$(DEPS)
		cat $(DEPS) > $(DEP_FILE)

size:		$(OBJDIR) $(TARGET_HEX)
		$(SIZE) $(TARGET_HEX)


.PHONY:	all clean depends upload reset size  monitor

include $(DEP_FILE)
