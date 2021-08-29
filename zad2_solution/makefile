PROGRAMS = example
CC = gcc
N = 10
CFLAGS = -DN=$(N) -Wall -Wextra -O2 -std=c11

all: $(PROGRAMS)

notec.o: notec.asm
	nasm -DN=$(N) -f elf64 -o $@ $<

example.o: example.c
	$(CC) -c $(CFLAGS) -o $@ $<

example: example.o notec.o
	$(CC) -pthread -o $@ $^

.PHONY: all clean

clean:
	rm -rf $(PROGRAMS) *.o