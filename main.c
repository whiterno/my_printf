#include <stdio.h>

extern void myPrintf();

int main(){
    int a = 1;
    int* p = &a;
    myPrintf("%s %d %x %c %%%% 12 3 13 12 3  \n", "Hello", -1, 53, '0');
    printf("Done\n");
}
