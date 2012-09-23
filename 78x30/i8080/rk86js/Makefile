.PHONY: build files

all: build files
	
ifeq ($(OS),Windows_NT)
  CC = c:/tcc/tcc
  EXE = .exe
else
  CC = cc
endif

build:
	$(CC) -o rkdump rkdump.c
	
files:
	(cd files && ls -1 >../files.lst)
	(cd files && ../rkdump <../files.lst) > files.js

clean:
	-rm files.lst rkdump$(EXE) files.js
	-rm files/rk86demo.bin
