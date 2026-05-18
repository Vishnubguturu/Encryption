    // version 1.1 10/29/2022 //
#ifndef MYMAIN_S
#else
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // imports
    #include "main.h"
    #include "rdbuf.h"
    #include "setup.h"
    #include "cipher.h"
    .extern fwrite
    .extern stdin
    .extern stdout
    .extern stderr

    .section .rodata
    // do not change these error messages
.Lbdrd:  .string "%s: read failed\n"
.Lbdwr:  .string "%s: write failed\n"

    .text

    //
    // encrypter -b bookfile
    //
    // int main(int argc, char **argv)
    // int main(r0=argc, r1=argv)

    .global main
    .type   main, %function

    //
    // stack frame layout
    //
    // TODO Part 2: complete the following stack frame design
    // You can change or delete any comments in this file
    //
    .equ    FP_OFF,     32          // fp offset in main stack frame
    .equ    FPBOOK,     FP_OFF + 4            // FILE * to book file
    .equ    IOBUF,      FPBOOK + BUFSZ            // buffer for input file
    .equ    BOOKBUF,    IOBUF + BUFSZ            // buffer for book file
    .equ    ARGV0,      BOOKBUF + 4            // save argv[0] for error printing
    //
    // add your local variables here if you need them:
    // NOTICE: Adjust PAD so FRMADD + FP_OFF + 4 divides by 8 EVENLY!
    //
    .equ    PAD,        0            // Stack frame PAD
    .equ    OARG5,      ARGV0 + 4            // output arg5 must be at bottom
    .equ    FRMADD,    OARG5-FP_OFF // space in frame for locals+passed args

    // TODO Part 2: list how you are using the preserved registers
    // preserved register use
    // r4 = iobuf
    // r5 = bookbuf
    // r6 = fpbook
    // r7 = stdin
    // r8 
    // r9
    // r10

main:
    push    {r4-r10, fp, lr}        // push all the usable preserved registers
    add     fp, sp, FP_OFF          // set frame pointer to frame base
    ldr     r3, =FRMADD             // get space needed for locals+passed args
    sub     sp, sp, r3              // allocate space for locals and passed args 
     
    // save argv[0] in argv0
    // at the entry to main() argc is in r0 and argv is in r1.
    // call int setup(r0=argc, r1=argv, r2=*FPBOOK)
    // r2 is output parameter. Get the addresses of where
    // FPBOOK is located on main()'s stack and put this in r2
    // so setup can fill it in (passing a pointer to a local variable in r2)
    // if setup fails, put EXIT_FAILURE in r0 and then branch to .Lexit

    ldr r4, [r1]
    ldr r5, =ARGV0 
    str r4, [fp, -r5] // argv0 = argv[0]
    ldr r2, =FPBOOK
    sub r2, fp, r2 // r2 = pointer to fpbook
    bl setup // calling the setup function
    cmp r0, -1 // condition for EXIT_FAIL(-1) for setup
    bne .Lsetupnotfail // if setup doesn't return -1 branch to .Lsetupnotfail
    mov r0, 1 // r0 = EXIT_FAIL
    b .Lexit // branch to .Lexit
.Lsetupnotfail:

    // set up for main loop
    // save the variables you need in the preserved registers as you will be making
    // function calls in the loop body below and r0-r3 will be used for that

    ldr r4, =IOBUF
    sub r4, fp, r4
    ldr r5, =BOOKBUF
    sub r5, fp, r5
    ldr r6, =FPBOOK
    ldr r6, [fp, -r6]
    ldr r7, =stdin
    ldr r7, [r7]
    ldr r8, =OARG5
    str r5, [fp, -r8]

.Lloop:
    // this is a loop that runs until rdbuf indicates the EOF on stdin
    // was reached or there was an error.
    // int rdbuf(r0=stdin, r1=fpbook, r2=BUFSZ, r3=iobuf,OARG5=bookbuf)
    // NOTICE that the 5th arg is on the stack so you need to str the 
    // address of bookbuf at offset OARG5 on the stack
    // if r0 on return from rdbuf has a 0 in r0 we are done, 
    // branch to .Ldone (EXIT_SUCCESS is a 0)
    // if return less than 0, error print to stderr .Lbdrd, 
    // Put EXIT_FAILURE in r0 and go to .Ldone

    mov r0, r7 //r0 = stdin
    mov r1, r6 //r1 = *fpbook
    mov r2, BUFSZ //r2 = bufsz
    mov r3, r4 //r3 = iobuf
    bl rdbuf // calling the rdbuf function
    mov r9, r0 // r9 = bytes = cnt
    cmp r9, 0 // condition for rdbuf in main if it returns 0
    bne .Lcntnotzero // if rdbuf doesn't return 0 branch to .Lcntnotzero
    b .Ldone // branch to .Ldone if rdbuf returns 0
.Lcntnotzero:
    cmp r9, 0 // condition for rdbuf if cnt > 0
    bgt .Lnotlessthanzero // branch to .Lnotlessthanzero if cnt > 0
    ldr r0, =stderr // r0 = stderr
    ldr r0, [r0]
    ldr r1, =.Lbdrd // r1 = .Lbdrd 
    ldr r2, [fp, -ARGV0] // r2 = argv0 
    bl fprintf // printing to stderr 
    mov r0, 1 // r0 = EXIT_FAIL
    b .Ldone // branch to .Ldone
.Lnotlessthanzero:

    // call either encrypt
    // int encrypt(r0=char *iobuf, r1=char *bookbuf, r2=int cnt)
    // returns cnt

    mov r0, r4 // r0 = iobuf
    mov r1, r5 // r1 = bookbuf
    mov r2, r9 // r2 = cnt
    bl encrypt // calling the encrypt function

    // make sure to save cnt so we can check that fwrite wrote cnt characters
    // fwrite returns number of characters it wrote.
    // fwrite(r0=iobuf, r1=1, r2=cnt, r3=*stdout)
    // if cnt characters written go to .Lloop (write is ok)
    // othewise error, print to stderr .Lbdwr, put EXIT_FAILURE in r0
    // and fall through to .Ldone

    mov r10, r0 // r10 = cnt from encrypt
    mov r0, r4 // r0 = iobuf
    mov r1, 1 // r1 = 1
    mov r2, r10 // argument r2 = cnt for fwrite
    ldr r3, =stdout // r3 = stdout
    ldr r3, [r3] 
    bl fwrite // calling the fwrite function
    cmp r0, r10 // comparing cnt from encrypt and number of elements written from fwrite
    beq .Lloop // if cnt characters are written branch to .Lloop
    ldr r0, =stderr // r0 = stderr
    ldr r0, [r0]
    ldr r1, =.Lbdwr // r1 = .Lbdwr
    ldr r9, =ARGV0
    ldr r2, [fp, -r9] // r2 = argv0 
    bl fprintf // printing to stderr
    mov r0, 1 // r0 = EXIT_FAIL
    
.Ldone:
    // normal exit, call fclose of fpbook and fall through
    // to .Lexit

    mov r9, r0
    mov r0, r6
    bl fclose // calling the fclose function
    mov r0, r9
    b .Lexit // falling through to .Lexit

.Lexit:
    add     sp, sp, FRMADD
    sub     sp, fp, FP_OFF
    pop     {r4-r10, fp, lr}
    bx      lr

    .size   main, (. - main)
    .section .note.GNU-stack,"",%progbits
.end
#endif
