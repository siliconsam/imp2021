#include <stdio.h>

int main () {
   FILE *fp;
   char c;

   fp = fopen("file.txt", "w");

   c = fgetc(fp);
   if( ferror(fp) ) {
      printf("Error in reading from file : file.txt\n");
   }
   clearerr(fp);
   
   if( ferror(fp) ) {
      printf("Error in reading from file : file.txt\n");
   }
   fclose(fp);

   return(0);
}


