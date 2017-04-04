export PROJECT = getdate
export PROJECTRELEASEDIR = /nfs/gate/projects.zoidtechnologies.com/80/html/$(PROJECT)/

export datestamp = $(shell date +%Y%m%d-%H%M)
export archivename = $(PROJECT)-$(datestamp)-$(USER)

all: getdate.so

clean:
	-rm -f *.o *~ a.out core getdate.tab.*

distclean: clean
	-rm -f getdate.so

getdate.tab.c: getdate.y
	bison --output-file=getdate.tab.c getdate.y

getdate.tab.o: getdate.tab.c
	gcc -Wall -shared -fPIC -c -o getdate.tab.o getdate.tab.c

getdate.o: getdate.c
	gcc -Wall -shared -fPIC -c -I/usr/include/python2.4/ -o getdate.o getdate.c

getdate.so: getdate.o getdate.tab.o
	gcc -shared -fPIC -o getdate.so getdate.o getdate.tab.o

install: getdate.so
	install getdate.so /usr/lib/python2.4/site-packages/

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
