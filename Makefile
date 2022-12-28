CC=g++
CFLAGS=-g -O0 -Wall -fPIC 
OS_TARGET=scetool
SHARED_TARGET=libscetool.so
LDFLAGS=-lz
BUILDFOLDER=build
OBJS=aes.o aes_omac.o bn.o ec.o ecdsa.o frontend.o getopt.o keys.o list.o \
	main.o mt19937.o np.o rvk.o sce.o self.o sha1.o tables.o util.o spp.o
.SILENT:
.SUFFIXES: .c .cpp .o

ifdef CROSS_COMPILE_WIN32
CC = i686-w64-mingw32-g++
LDFLAGS = -static-libgcc -Wl,-Bstatic -lz
BUILDFOLDER = build-win32
SHARED_TARGET = libscetool.dll
endif

ifdef CROSS_COMPILE_WIN64
CC = x86_64-w64-mingw32-g++
LDFLAGS = -static-libgcc -Wl,-Bstatic -lz
BUILDFOLDER = build-win64
SHARED_TARGET = libscetool.dll
endif

all: $(OS_TARGET) $(SHARED_TARGET)
.PHONY: all

$(OS_TARGET): $(OBJS)
	${LINK}
	# Build the scetool executable
	if cd $(BUILDFOLDER); $(CC) $(CFLAGS) $(OBJS) -o $(OS_TARGET) $(LDFLAGS) $(LIBS); then \
		${LINK_OK}; \
	else \
		${LINK_FAILED}; \
	fi

$(SHARED_TARGET): $(OBJS)
	${LINK}
	# Build the scetool shared library
	if cd $(BUILDFOLDER); $(CC) -shared $(CFLAGS) $(OBJS) -o $(SHARED_TARGET) $(LDFLAGS) $(LIBS); then \
		${LINK_OK}; \
	else \
		${LINK_FAILED}; \
	fi

%.o: %.c
	mkdir -p $(BUILDFOLDER)
	${COMPILE_STATUS}
	if ${CC} ${CFLAGS} ${CFLAGS} -c -o $(BUILDFOLDER)/$@ $<; then \
		${COMPILE_OK}; \
	else \
		${COMPILE_FAILED}; \
	fi

%.o: %.cpp
	mkdir -p $(BUILDFOLDER)
	${COMPILE_STATUS}
	if ${CC} ${CFLAGS} ${CFLAGS} -c -o $(BUILDFOLDER)/$@ $<; then \
		${COMPILE_OK}; \
	else \
		${COMPILE_FAILED}; \
	fi

clean:
	@printf "\033[K\033[0;32mCleaning\033[1;32m\033[0;32m...\033[0m\n"
	rm -rf build/* $(OS_TARGET) $(SHARED_TARGET)

install:
	@printf "\033[K\033[0;32mInstalling\033[1;32m\033[0;32m...\033[0m\n"
	install -m755 $(OS_TARGET) $(BINDIR)

DIR_ENTER = printf "\033[K\033[0;36mEntering directory \033[1;36m$$i\033[0;36m.\033[0m\n"; cd $$i || exit 1
DIR_LEAVE = printf "\033[K\033[0;36mLeaving directory \033[1;36m$$i\033[0;36m.\033[0m\n"; cd .. || exit 1
DEPEND_STATUS = printf "\033[K\033[0;33mGenerating dependencies...\033[0m\r"
DEPEND_OK = printf "\033[K\033[0;32mSuccessfully generated dependencies.\033[0m\n"
DEPEND_FAILED = printf "\033[K\033[0;31mFailed to generate dependencies!\033[0m\n"; exit 1
COMPILE_STATUS = printf "\033[K\033[0;33mCompiling \033[1;33m$<\033[0;33m...\033[0m\r"
COMPILE_OK = printf "\033[K\033[0;32mSuccessfully compiled \033[1;32m$<\033[0;32m.\033[0m\n"
COMPILE_FAILED = printf "\033[K\033[0;31mFailed to compile \033[1;31m$<\033[0;31m!\033[0m\n"; exit 1
LINK_STATUS = printf "\033[K\033[0;33mLinking \033[1;33m$@\033[0;33m...\033[0m\r"
LINK_OK = printf "\033[K\033[0;32mSuccessfully linked \033[1;32m$@\033[0;32m.\033[0m\n"
LINK_FAILED = printf "\033[K\033[0;31mFailed to link \033[1;31m$@\033[0;31m!\033[0m\n"; exit 1
INSTALL_STATUS = printf "\033[K\033[0;33mInstalling \033[1;33m$$i\033[0;33m...\033[0m\r"
INSTALL_OK = printf "\033[K\033[0;32mSuccessfully installed \033[1;32m$$i\033[0;32m.\033[0m\n"
INSTALL_FAILED = printf "\033[K\033[0;31mFailed to install \033[1;31m$$i\033[0;31m!\033[0m\n"; exit 1
DELETE_OK = printf "\033[K\033[0;34mDeleted \033[1;34m$$i\033[0;34m.\033[0m\n"
DELETE_FAILED = printf "\033[K\033[0;31mFailed to delete \033[1;31m$$i\033[0;31m!\033[0m\n"; exit 1

