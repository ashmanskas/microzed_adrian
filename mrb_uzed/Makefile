
V = ~/bin/VIVADO171

all :
	make clean
	make build
	make compile

build:
	$(V) -mode batch -source build.tcl

compile:
	$(V) -mode batch -source compile.tcl
	./promgen.sh

promgen:
	./promgen.sh

clean :
	-/bin/rm -rf *~
	-/bin/rm -rf proj
	-/bin/rm -rf *.cfi
	-/bin/rm -rf *.prm
	-/bin/rm -rf *.jou
	-/bin/rm -rf *.backup.log
