// version 1.0 11/12/2022
#include <stdio.h>
#include "cipher.h"

#ifdef MYENCRYPT_C
TODO("using Cencrypt.c");

int
encrypt(char *iobuf, char *bookbuf, int cnt)
{

    // your code here
    if(cnt < 0){
        return 0;
    }

    size_t input_byte = 0;
    size_t book_byte = 0;

    for(int i = 0; i < cnt; i++){
        input_byte = iobuf[i];
        book_byte = bookbuf[i];
        iobuf[i] = input_byte ^ book_byte;
    }

    return cnt;
}

#elif defined MYENCRYPT_S
TODO("using encrypt.S");
#else
TODO("using solution encrypt");
#endif
