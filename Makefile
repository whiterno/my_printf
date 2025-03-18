build:
	nasm -f elf64 -o my_printf.o my_printf.s
	ld -o my_printf my_printf.o
