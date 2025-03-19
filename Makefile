build:
	nasm -f elf64 -o my_printf.o my_printf.s
	gcc  -no-pie main.c my_printf.o -o main
