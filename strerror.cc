#include <stdio.h>

char *strerror(int errnum) {
    static char rv[100];

    sprintf(rv, "error number %d", errnum);
    return rv;
}
