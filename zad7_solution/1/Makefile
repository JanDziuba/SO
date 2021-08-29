.PHONY: install all

all:
	yes | pkgin install nasm
	nasm -f bin custom_bl.s -o custom_bl

install: all
	dd bs=512 count=1 seek=2 if=/dev/c0d0 of=/dev/c0d0
	dd bs=512 count=1 if=custom_bl of=/dev/c0d0
	dd bs=512 count=1 seek=1 if=message.txt of=/dev/c0d0
	dd bs=1 count=1 seek=1023 if=/dev/zero of=/dev/c0d0
