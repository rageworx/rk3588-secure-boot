# Makefile for POSIX
# Modified by Raphael Kim [rageworx@gmail.com]

TARGET := enable-sb

BINDIR = bin
SRCDIR = src
OBJDIR = obj

OBJS += $(OBJDIR)/entry.o
OBJS += $(OBJDIR)/main.o
OBJS += $(OBJDIR)/exceptions.o
OBJS += $(OBJDIR)/libc.o
OBJS += $(OBJDIR)/otp.o
OBJS += $(OBJDIR)/printf.o
OBJS += $(OBJDIR)/putchar.o
OBJS += $(OBJDIR)/swd.o
OBJS += $(OBJDIR)/uart.o
OBJS += $(OBJDIR)/vbar.o

# Updated : AARCH64 cross compiler targeted to 
#        https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
PREFIX = aarch64-none-linux-gnu-
USE_CLANG = 0

# Test clang availed ?
COMPILER_VERSION := $(shell $(CXX) --version)
ifneq '' '$(findstring clang,$(COMPILER_VERSION))'
    USE_CLANG = 1
endif

ifeq ($(USE_CLANG),0)
CC = $(PREFIX)gcc
else
ifeq ($(OS),Windows_NT)
CC = clang --target=aarch64
else
CC = clang --target=aarch64 -isystem /usr/aarch64-linux-gnu/include
endif
endif

AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
RM = rm -f
ECHO = echo -e

CFLAGS =  -c -O2 -Wall -Werror -std=c11 -MMD
ifeq ($(USE_CLANG),1)
CFLAGS += -Weverything
CFLAGS += -mno-unaligned-access
endif
CFLAGS += -U_FORTIFY_SOURCE
CFLAGS += -mgeneral-regs-only
CFLAGS += -fno-stack-protector
CFLAGS += -fno-builtin-printf
CFLAGS += -fno-builtin
## These two flags may not supported by latest version of GCC
# CFLAGS += -Wno-reserved-macro-identifier
# CFLAGS += -Wno-reserved-identifier
## ----------------------------------------------------------
CFLAGS += -DPRINTF_INCLUDE_CONFIG_H
CFLAGS += -Ihw

DEPS = $(OBJS:.o=.d)

.PHONY: preparedir

all: preparedir $(BINDIR)/$(TARGET)

preparedir:
	@mkdir -p $(OBJDIR)
	@mkdir -p $(BINDIR)

$(BINDIR)/$(TARGET): $(OBJDIR)/$(TARGET).elf
	@$(ECHO) "Generating $@ ... "
	@$(OBJCOPY) -O binary $< $@

$(OBJDIR)/$(TARGET).elf: $(OBJS)
	@$(ECHO) "Generating ELF image : $@ ... "
	@$(LD) $^ -o $@ -T linker.ld

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@$(ECHO) "Compiling $< ... "
	@$(CC) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.S
	@$(ECHO) "Compiling $< ... "
	@$(CC) -c -D__ASSEMBLY__ $< -o $@

error/failure:
	$(ECHO) -e "Error."
	exit 1

-include $(DEPS)

clean:
	@$(ECHO) "Cleaning ... "
	@$(RM) $(BINDIR)/$(TARGET).bin 
	@$(RM) $(OBJDIR)/$(TARGET).elf 
	@$(RM) $(OBJS) 
	@$(RM) $(DEPS)
	@$(ECHO) "Done."

