CC = gcc
HOSTCC = gcc
PREFIX = /usr/local

.PHONY: all clean install tools fuse tests libglfs-host libglfs-target build-dir
all: tools tests libglfs-host libglfs-target fuse

build-dir:
	mkdir -p build/tools
	mkdir -p build/host-libglfs
	mkdir -p build/target-libglfs

TOOLS_SOURCE = $(shell find tools -name '*.c')
TOOLS = $(patsubst tools/%.c, build/tools/%, $(TOOLS_SOURCE))
TOOLS_INSTALL = $(patsubst build/tools/%, $(PREFIX)/bin/%, $(TOOLS))

tools: $(TOOLS)

build/tools/%: tools/%.c build/host-libglfs.a | build-dir
	$(HOSTCC) $(HOST_CFLAGS) -o $@ -Ilibglfs/include $^

FUSE_SOURCE = $(shell find fuse -name '*.c')
FUSE_CFLAGS = $(shell pkg-config fuse3 --cflags)
FUSE_LIBS = $(shell pkg-config fuse3 --libs)

fuse: build/tools/glfs-fuse

build/tools/glfs-fuse: $(FUSE_SOURCE) build/host-libglfs.a | build-dir
	$(HOSTCC) $(HOST_CFLAGS) -o $@ $(FUSE_CFLAGS) -Ilibglfs/include $^ $(FUSE_LIBS)

tests: build/test

build/test: test.c | build-dir
	$(HOSTCC) $(HOST_CFLAGS) -o build/test -Ilibglfs/include test.c

LIBGLFS_SOURCE = $(shell find libglfs/src -name '*.c')
LIBGLFS_HOST_OBJECTS = $(patsubst libglfs/src/%.c, build/host-libglfs/%.o, $(LIBGLFS_SOURCE))
LIBGLFS_OBJECTS = $(patsubst libglfs/src/%.c, build/target-libglfs/%.o, $(LIBGLFS_SOURCE))

libglfs-host: build/host-libglfs.a build/host-libglfs.so
libglfs-target: build/target-libglfs.a

build/host-libglfs.a: $(LIBGLFS_HOST_OBJECTS)
	$(AR) rcs $@ $^

build/host-libglfs.so: $(LIBGLFS_HOST_OBJECTS)
	$(HOSTCC) -shared -o $@ $^

build/target-libglfs.a: $(LIBGLFS_OBJECTS)
	$(AR) rcs $@ $^

build/host-libglfs/%.o: libglfs/src/%.c | build-dir
	$(HOSTCC) $(HOST_CFLAGS) -fPIC -Ilibglfs/include -c -o $@ $<

build/target-libglfs/%.o: libglfs/src/%.c | build-dir
	$(CC) $(CFLAGS) -Ilibglfs/include -c -o $@ $<

install: $(TOOLS_INSTALL) $(PREFIX)/bin/glfs-fuse libglfs-host
	mkdir -p $(PREFIX)/lib
	mkdir -p $(PREFIX)/include/glfs
	install -m 755 build/host-libglfs.a build/host-libglfs.so $(PREFIX)/lib
	install -m 644 libglfs/include/glfs/* $(PREFIX)/include/glfs
	ldconfig

$(PREFIX)/bin/%: build/tools/% | $(PREFIX)/bin
	install -m 755 $< $@

$(PREFIX)/bin:
	@mkdir -p $(PREFIX)/bin

clean:
	rm -rf build
