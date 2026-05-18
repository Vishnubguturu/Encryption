#ifndef MYRDBUF_S
#else
// version 1.1 11/29/2022 //
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // global constants
    #include "cipher.h"

    .extern fread
    .extern feof
    .extern ferror
    .text

    // int rdbuf(r0=FILE *in, r1=FILE *fpbook, r2=int cnt, r3=char *iobuf, 
    //            on the stack at ARG5 offset=char *bookbuf)
    // returns number of bytes read EXIT_FAIL otherwise
    // you can change or remove any comments in this file

    .type   rdbuf, %function
    .global rdbuf
    .equ    ARG5,  4 
    .equ    FP_OFF, 28
 
rdbuf:
    push    {r4-r9, fp, lr}
    add     fp, sp, FP_OFF

    // save the register args (r0-r3) into preserved registers
    // as there are many function calls
   
    mov r4, r0 // r4 = in
    mov r5, r1 // r5 = fpbook
    mov r6, r2 // r6 = cnt (BUFSZ)
    mov r7, r3 // r7 = iobuf
 
    // check for end of file feof(in)
    // if r0 is not zero at EOF, set r0 to 0 and return
    // otherwise check for read errors
    // check for error ferror(in)
    // if r0 is zero, no errors, do the reads
    // if r0 is not zero, set r0 to EXIT_FAIL and return

    bl feof // calling the feof function
    cmp r0, #0 // comparing r0 and 0 for EOF
    bne .Lnotfeof // branch to .Lnotfeof if r0 is not 0
    mov r0, r4 // r0 = in
    bl ferror // calling the function ferror
    cmp r0, #0 // checking if r0 is 0
    beq .Lnoerror // branch to .Lnoerror if r0 is 0
    mov r0, #-1 // setting r0 to EXIT_FAIL 
    b .Ldone // return
.Lnotfeof:
    mov r0, #0 // setting r0 to 0
    b .Ldone // return
.Lnoerror:

    // bytes = fread(r0=iobuf, r1=1, r2=cnt, r3=in)
    // save bytes so we can check that we read same bytes from bookfile
    // if r0 <= 0 return with r0 = 0

    mov r0, r7 // r0 = iobuf
    mov r1, #1 // r1 = 1
    mov r2, r6 // r2 = cnt
    mov r3, r4 // r3 = in
    bl fread // calling the fread function
    cmp r0, #0 // checking if r0 is 0
    bgt .Lbytesgtzero // if r0 > 0 branch to .Lbytesgtzero
    mov r0, #0 // r0 = 0
    b .Ldone // return
.Lbytesgtzero:

    // r0 = fread(r0=bookbuf, r1=1, r2=bytes, r3=fpbook)
    // the pointer to bookbuf is passed on the stack so
    // you need to do a ldr from ARG5 offset to get the address
    // to pass to the fread
    // if r0 on the return from fread is not equal to bytes 
    // (bytes is the value returned in r0 from the fread into iobuf above),
    // then return EXIT fail
    // otherwise set r0 = bytes and return

    mov r8, r0 // r8 = r0 bytes
    ldr r0, [fp, ARG5] // r0 = bookbuf
    mov r1, #1 // r1 = 1
    mov r2, r8 // r2 = bytes
    mov r3, r5 // r3 = fpbook
    bl fread // calling fread again
    cmp r0, r8 // checking if fread returns the same number as bytes
    beq .Lr0isbytes // branch to .Lr0isbytes if r0 is equal to bytes
    mov r0, #-1 // r0 = EXIT_FAIL
    b .Ldone // return
.Lr0isbytes:
    mov r0, r8 // r0 = bytes
    b .Ldone // return

.Ldone:
    sub     sp, fp, FP_OFF
    pop     {r4-r9, fp, lr}
    bx      lr

    .size   rdbuf, (. - rdbuf)
    .section .note.GNU-stack,"",%progbits
.end
#endif
