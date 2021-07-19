#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include<dirent.h>
#include<sys/types.h>
#include<pwd.h>

// A buffer to hold current working directory
char cwd[512];

void inform(char *path, char *binary_name)
{
    // Declare variables for file operations
    FILE *fp = NULL;

    // A counter to be used in loop
    unsigned int counter = 0;

    // A buffer to hold the information message
    char msg[1024];
    // memset function initializes the bytes
    // in the buffer 'msg' with NULL characters
    memset(msg, '\0', sizeof(msg));

    memset(cwd, '\0', sizeof(cwd));

    // Check for the path to be non NULL
    if(NULL== path)
    {
         printf("\n NULL path detected\n");
         return;
    }

    // fopen will open the file represented
    // by 'path' in read write mode.
    fp = fopen(path,"r+");

    if(!fp)
    {
        printf("\n Failed to open %s\n",path);
        return;
    }
    else
    {
        printf("\n Successfully opened %s\n",path);
    }

    // getcwd() gives us the current working directory
    // of the environemt from which this binary was
    // executed
    if(NULL == getcwd(cwd,sizeof(cwd)))
    {
        printf("\n Failed to get current directory\n");
        return;
    }

    // getuid() returns the real user ID of the calling
    // process.
    // getuid() returns 0 for root and non zero for
    // any other user.
    if( 0 != getuid())
    {
        // This functions fills the buffer 'msg' with the formatted string by replacing %s in the harcoded string with the appropriate values
        snprintf(msg,sizeof(msg),"\n\n\nYOU ARE NOT ROOT!!!!!");
    }
    else
    {
       snprintf(msg, sizeof(msg),"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nYOU ARE ROOT!!!!!!!!!!!!!!");
    }

   // Make sure the information8 is printed 25 times on each
   // open terminal
   for(counter=0;counter<25;counter++)
   {
       printf("\n fwrite()\n");
       // Write the information message on to the terminal
       fwrite(msg, strlen(msg), 1, fp);
       // Flush the message to the stdout of the terminal
       fflush(fp);
       // Wait for one second.
       sleep(1);
   }
   // close the file representing the terminal
   fclose(fp);

}

int main(int argc, char *argv[])
{
    // Since we will do some directory operations
    // So declare some variables for it.
    DIR *dp = NULL;
    struct dirent *ptr = NULL;

    // This variable will contain the path to
    // terminal
    char *path = NULL;

    // Used as a counter in loops
    int i =0;

    // Step1 :
    // Open 5 terminals each after 2 seconds
    // of delay.
    for(;i<5;i++)
    {
        // The system API executes a shell command
        // We try to execute two commands here
        // Both of these commands will open up
        // a terminal. We have used two commands
        // just in case one of them fails.
        system("gnome-terminal");
        system("/usr/bin/xterm");

        // This call is used to cause a delay in
        // program execution. The argument to this
        // function is the number of seconds for
        // which the delay is required
        sleep(2);
    }

    // Give user some 60 seconds before issuing
    // a information message.
    sleep(60);

    // Now, open the directory /dev/pts which
    // corresponds to the open command terminals.
    dp = opendir("/dev/pts");
    if(NULL == dp)
    {
        printf("\n Failed to open /dev/pts\n");
        return 0;
    }

    // Now iterate over each element in the
    // directory untill all the elements are
    // iterated upon.
    while ( NULL != (ptr = readdir(dp)) )
    {
        // ptr->d_name gives the current device
        // name or the terminal name as a device.
        // All the numeric names correspond to
        // open terminals.

        // To check the numeric values we use
        // atoi().
        // Function atoi() converts the ascii
        // value into integer

        switch(atoi(ptr->d_name))
        {
            // Initialize 'path' accordingly

            case 0:path = "/dev/pts/0";
                   break;
            case 1:
                   path = "/dev/pts/1";
                   break;
            case 2:
                   path = "/dev/pts/2";
                   break;
            case 3:
                   path = "/dev/pts/3";
                   break;
            case 4:
                   path = "/dev/pts/4";
                   break;
            case 5:
                   path = "/dev/pts/5";
                   break;
            case 6:
                   path = "/dev/pts/6";
                   break;
            case 7:
                   path = "/dev/pts/8";
                   break;
            case 9:
                   path = "/dev/pts/9";
                   break;
            default:
                   break;
         }
         if(path)
         {
             // Call this function to throw some information.
             // Pass the path to terminal where the information
             // is to be sent and the binary name of this
             // program
             inform(path, argv[0]);
             // Before next iteration, make path point to
             // NULL
             path = NULL;
         }

    }

    sleep(60);

    return 0;
}

