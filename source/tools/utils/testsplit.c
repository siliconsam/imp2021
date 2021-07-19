#include <stdio.h>
#include <string.h>

int main()
{
	char str[] = "file1,file2,file3/file4,file5,file6,file7";
//	int init_size = strlen(str);
	char delim0[] = "/";
	char delim1[] = ",";

	char *ptr;
    char *fptr;
    int count;
    int fcount;

    char iptr[sizeof(str)];
    char optr[sizeof(str)];

//    ptr = strtok(str, delim0);
//    count = 0;
//	while (ptr != NULL)
//	{
//        if (count == 0)
//        {
//            printf("Input files = '%s'\n", ptr);
//            strcpy(iptr,ptr);            
//            fptr = strtok(iptr, delim1);
//            fcount = 0;
//            while (fptr != NULL)
//            {
//                printf("Input file#'%d' = '%s'\n", fcount,fptr);
//		        fptr = strtok(NULL, delim1);
//                fcount++;
//            }                
//        }
//        else
//        {
//		    printf("Output files = '%s'\n", ptr);
//            strcpy(optr,ptr);            
//        }
//		ptr = strtok(NULL, delim0);
//        count++;
//	}

    printf("\nSplitting file list '%s'\n", str);
    ptr = strtok(str, "/,");
    count = 0;
	while (ptr != NULL)
	{
        printf("File#'%d' = '%s' in '%s'\n", count, ptr,str);
		ptr = strtok(NULL, "/,");
        count++;
	}

//	ptr = strtok(optr, delim1);
//    count = 0;
//	while (ptr != NULL)
//	{
//        printf("Output file#'%d' = '%s'\n", count,ptr);
//		ptr = strtok(NULL, delim1);
//        count++;
//	}

	return 0;
}
