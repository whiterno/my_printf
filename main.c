#include <stdio.h>

extern void myPrintf();

int main(){
    int a = 1;
    int* p = &a;
    myPrintf("%s What do you think?\n", "123456789Moment of truth");
    printf("Done\n");
}
