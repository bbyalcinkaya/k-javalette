all: build 

build:
		kompile src/javalette.md -w all -v --gen-bison-parser --directory . -O2
		
		bash makejlc

builddebug:
		kompile src/javalette.md -w all -v --debug --directory . --backend haskell


test:
		./test-typecheck.sh	

clean:
		rm -r .kompile* .kparse* javalette-kompiled

pack: 
		tar -czvf partC-3.tar.gz doc lib src Makefile jlc runner makejlc
