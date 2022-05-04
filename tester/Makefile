all: build 

build:
		kompile randomize.md -w all -v --directory . -O2 --gen-bison-parser
		

builddebug:
		kompile randomize.md -w all -v --debug --directory . --backend haskell


clean:
		rm -r .kompile* .kparse* randomize-kompiled


