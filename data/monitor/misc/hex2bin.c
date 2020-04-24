#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//=======================================================================
//  hex2bin.c
//
//  Converts Intel-hex files to binary
//
//  Expects the filename without extension on the command line
//  and produces an output file <filename>.bin in the current directory.
//  The input file must have a .hex extension.  Full pathnames can be
//  used from the command line.
//
//=======================================================================

int aton(unsigned char);

main(int argc, char *argv[]) {

    FILE  *infile;             // input  file pointer
    FILE  *otfile;             // output file pointer

    unsigned char  fnami[50];  // input  file name
    unsigned char  fnamo[50];  // output file name

    int  count = 0;
    int  u, t;

    strcpy(fnami, argv[1]);
    strcat(fnami, ".hex");     // input  file name

    strcpy(fnamo, argv[1]);
    strcat(fnamo, ".bin");     // output file name

    if ((infile = fopen(fnami, "rb")) == NULL) {
        printf("ERROR: Cannot open file for reading\n");
        exit(0);
    }

    otfile = fopen(fnamo, "wb");
    while (1) {
        // look for start of line
        while (fgetc(infile) != ':');
        // next two characters are byte count
        if ((t = 16 * aton(fgetc(infile)) + aton(fgetc(infile))) == 0) {
            fclose(infile);
            fclose(otfile);
            exit(0);
        }
        u = 16 * 16 * 16 * aton(fgetc(infile)) + 16 * 16 * aton(fgetc(infile)) + 16 * aton(fgetc(infile)) + aton(fgetc(infile));

        fgetc(infile);
        fgetc(infile);
        while (u > count) {
            // there is a gap in the data and we
            // need to fill this gap with 0's
            fputc(0, otfile);
            count++;
        }
        while (u + t - count > 0) {
            fputc(16 * aton(fgetc(infile)) + aton(fgetc(infile)), otfile);
            // get next two ascii chars and turn them
            // into decimal value of byte to go
            count++;
        }
    }
}


// ascii character to a numerical value
//
int aton(unsigned char ch) {
    int n;
    if (ch < 0x3A)
        n = ch - 0x30;
    else
        n = ch - 0x37;
    return n;
}

