#include <stdio.h>

extern void myPrintf();

int main(){
    myPrintf("%s children %d %d\n", "Hello", 123, 345);
}
