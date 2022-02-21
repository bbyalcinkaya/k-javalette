
build:
		kompile javalette.md -O2 -w all -v --iterated --gen-bison-parser

test:
		./test-typecheck.sh	

clean:
		rm -r .kompile* .kparse* javalette-kompiled