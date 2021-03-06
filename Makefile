export PROJECT = getdate
export PROJECTRELEASEDIR = /nfs/gate/projects.zoidtechnologies.com/80/html/$(PROJECT)/

export datestamp = $(shell date +%Y%m%d-%H%M)
export archivename = $(PROJECT)-$(datestamp)-$(USER)


CC = gcc
CFLAGS = -g -O2
CPPFLAGS =
LDFLAGS =
LDLIBS =
LEX = lex
YACC = yacc
PYTHON = python

CFLAGS += -Wall -Wextra -Werror=missing-prototypes -Werror=missing-declarations -Werror=redundant-decls
override CFLAGS += -fPIC -fvisibility=hidden
override CPPFLAGS += $(shell ${PYTHON}-config --includes)
override LDFLAGS += -shared -Wl,-z,defs
override LDLIBS += $(shell ${PYTHON}-config --libs)

.SECONDARY:
.SUFFIXES:

all: libgetdate.so

clean:
	rm -f *.o *.so

distclean: clean
	rm -f *-parser.[ch]

# Actually generated by the same command, but multiple-output-files
# are awkward in Make.
%.h %.c : %.l
	${LEX} --header-file=$*.h -o $*.c $<
%.h %.c : %.y
	${YACC} --defines=$*.h -o $*.c $<
%.o: %.c
	${CC} ${CFLAGS} ${CPPFLAGS} -c -o $@ $<
%.so:
	${CC} ${LDFLAGS} $^ ${LDLIBS} -o $@

libgetdate.so: getdate-parser.o getdate-lexer.o
getdate-lexer.o: getdate-lexer.c getdate-parser.h

# TODO - should use setup.py to take care of this
install: libgetdate.so
	install libgetdate.so $(shell ${PYTHON} -c 'import site; print(site.getsitepackages()[0])')
	#install libgetdate.so $(shell ${PYTHON} -c 'import site; print(site.getusersitepackages())')

release:
	echo -n "making a new release of $(PROJECT): ";\
	pushd ../releases;\
	svn export http://aristotle/repos/$(PROJECT)/trunk/ $(archivename);\
	tar jcf $(archivename).tar.bz2 $(archivename)/*;\
	tar zcf $(archivename).tgz $(archivename)/*;\
	zip -r $(archivename).zip $(archivename)/*;\
	popd;\
	echo "[OK]"
	cp $(archivename).* $(PROJECTRELEASEDIR)
	install README.txt $(PROJECTRELEASEDIR)
