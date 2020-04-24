#include <stdio.h>
#include <stdlib.h>

// convert binary file to hex suitable for Verilog readmemh

int main(int argc, const char *argv[]) {

    if (argc != 2) {
        printf("Usage: bin2mem <filename.bin\n\n");
        exit(1);
    }
    int i = 0;
    FILE* fp = fopen(argv[1], "rb");
    if (fp) {
        int c;
        while ((c = fgetc(fp)) != EOF) {
            printf("%02x\n", c);
            i++;
        }
        fclose(fp);
    }
    else {
        printf("Could not open input file\n\n");
        exit(1);
    }

    // pad to 64k
    while (i<65536) {
      printf("00\n");
      i++;
    }
    exit(0);
}

