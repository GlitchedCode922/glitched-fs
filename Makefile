CC = gcc
PREFIX = /usr/local

all: tools build/test build/libglfs.a

build:
	mkdir -p build
	mkdir -p build/libglfs

TOOLS_SOURCE = $(shell find tools -name '*.c')
TOOLS = $(patsubst tools/%.c, build/%, $(TOOLS_SOURCE))
TOOLS_INSTALL = $(patsubst build/%, $(PREFIX)/bin/%, $(TOOLS))

tools: $(TOOLS)

build/%: tools/%.c build/libglfs.a | build
	$(CC) $(CFLAGS) -o $@ -Ilibglfs/include $^

build/test: test.c | build
	$(CC) $(CFLAGS) -o build/test -Ilibglfs/include test.c

LIBGLFS_SOURCE = $(shell find libglfs/src -name '*.c')
LIBGLFS_OBJECTS = $(patsubst libglfs/src/%.c, build/libglfs/%.o, $(LIBGLFS_SOURCE))

build/libglfs.a: $(LIBGLFS_OBJECTS)
	$(AR) rcs $@ $^

build/libglfs/%.o: libglfs/src/%.c | build
	$(CC) $(CFLAGS) -Ilibglfs/include -c -o $@ $<

install: $(TOOLS_INSTALL)

$(PREFIX)/bin/%: build/% | $(PREFIX)/bin
	install -m 755 $< $@

$(PREFIX)/bin:
	@mkdir -p $(PREFIX)/bin

clean:
	rm -rf build
