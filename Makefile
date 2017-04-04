export PROJECT = getdate
export PROJECTRELEASEDIR = /nfs/gate/projects.zoidtechnologies.com/80/html/$(PROJECT)/

export datestamp = $(shell date +%Y%m%d-%H%M)
export archivename = $(PROJECT)-$(datestamp)-$(USER)


CC = gcc
CFLAGS = -g -O2
CPPFLAGS =
LDFLAGS =
LDLIBS =
YACC = yacc
PYTHON = python

CFLAGS += -Wall
override CFLAGS += -fPIC
override CPPFLAGS += $(shell ${PYTHON}-config --includes)
override LDFLAGS += -shared

.SECONDARY:
.SUFFIXES:

all: getdate.so

clean:
	rm -f *.o *.so

distclean: clean
	rm -f *.tab.[ch]

%.tab.c: %.y
	${YACC} -o $@ $<
%.o: %.c
	${CC} ${CFLAGS} ${CPPFLAGS} -c -o $@ $<
%.so:
	${CC} ${LDFLAGS} $^ ${LDLIBS} -o $@

getdate.so: getdate.o getdate.tab.o

# TODO - should use setup.py to take care of this
install: getdate.so
	install getdate.so $(shell ${PYTHON} -c 'import site; print(site.getsitepackages()[0])')
	#install getdate.so $(shell ${PYTHON} -c 'import site; print(site.getusersitepackages())')

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
