# Makefile for busybox
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#


PROG=busybox
VERSION=0.37
BUILDTIME=$(shell date "+%Y%m%d-%H%M")

# Comment out the following to make a debuggable build
# Leave this off for production use.
DODEBUG=false
# If you want a static binary, turn this on.  I can't think
# of many situations where anybody would ever want it static, 
# but...
DOSTATIC=false

#This will choke on a non-debian system
ARCH=`uname -m | sed -e 's/i.86/i386/' | sed -e 's/sparc.*/sparc/'`

GCCMAJVERSION=`$(CC) --version | sed -n "s/^\([0-9]\)\.\([0-9].*\)[\.].*/\1/p"`
GCCMINVERSION=`$(CC) --version | sed -n "s/^\([0-9]\)\.\([0-9].*\)[\.].*/\2/p"`

GCCSUPPORTSOPTSIZE=$(shell \
if ( test $(GCCMAJVERSION) -eq 2 ) ; then \
    if ( test $(GCCMINVERSION) -ge 91 ) ; then \
	echo "true"; \
    else \
	echo "false"; \
    fi; \
else \
    if ( test $(GCCMAJVERSION) -gt 2 ) ; then \
	echo "true"; \
    else \
	echo "false"; \
    fi; \
fi; )


ifeq ($(GCCSUPPORTSOPTSIZE), true)
    OPTIMIZATION=-Os
else
    OPTIMIZATION=-O2
endif

# -D_GNU_SOURCE is needed because environ is used in init.c
ifeq ($(DODEBUG),true)
    CFLAGS+=-Wall -g -D_GNU_SOURCE -DDEBUG_INIT
    STRIP=
    LDFLAGS=
else
    CFLAGS+=-Wall $(OPTIMIZATION) -fomit-frame-pointer -fno-builtin -D_GNU_SOURCE
    LDFLAGS= -s
    STRIP= strip --remove-section=.note --remove-section=.comment $(PROG)
    #Only staticly link when _not_ debugging 
    ifeq ($(DOSTATIC),true)
	LDFLAGS+= --static
    endif
    
endif

ifndef $(PREFIX)
    PREFIX=`pwd`/busybox_install
endif

LIBRARIES=
OBJECTS=$(shell ./busybox.sh)
CFLAGS+= -DBB_VER='"$(VERSION)"'
CFLAGS+= -DBB_BT='"$(BUILDTIME)"'

all: busybox busybox.links

busybox: $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(PROG) $(OBJECTS) $(LIBRARIES)
	$(STRIP)

busybox.links:
	- ./busybox.mkll | sort >$@
	
clean:
	- rm -f $(PROG) busybox.links *~ *.o core 
	- rm -rf busybox_install

distclean: clean
	- rm -f $(PROG)

force:

$(OBJECTS):  busybox.def.h internal.h Makefile

install: busybox busybox.links
	./install.sh $(PREFIX)

whichversion:
	@echo $(VERSION)


dist: release

release: distclean
	(cd .. ; rm -rf busybox-$(VERSION) ; cp -a busybox busybox-$(VERSION); rm -rf busybox-$(VERSION)/CVS busybox-$(VERSION)/.cvsignore ; tar -cvzf busybox-$(VERSION).tar.gz busybox-$(VERSION)) 

