#include<stdio.h>
#include<stdlib.h>
#include<signal.h>
#include <Windows.h>

//sig value Description
//SIGABRT   Abnormal termination
//SIGFPE    Floating-point error
//SIGILL    Illegal instruction
//SIGINT    CTRL+C signal
//SIGSEGV   Illegal storage access
//SIGTERM   Termination request

volatile double d = 0.0f;

void sig_handler(int signum){
  printf("Inside handler function\n");
  signal(SIGILL,SIG_DFL);   // Re Register signal handler for default action
}

int main(){
  printf("Inside main function\n");
  printf("Signal SIGABRT=%d\n",SIGABRT);
  printf("Signal SIGFPE=%d\n",SIGFPE);
  printf("Signal SIGILL=%d\n",SIGILL);
  printf("Signal SIGINT=%d\n",SIGINT);
  printf("Signal SIGSEGV=%d\n",SIGSEGV);
  printf("Signal SIGTERM=%d\n",SIGTERM);

  signal(SIGILL,sig_handler); // Register signal handler
  printf("Inside main function\n");
  for(int i=1;;i++){    //Infinite loop
    printf("%d : Inside main function\n",i);
    raise(SIGILL);
    Sleep(1000);  // Delay for 1 second (units in milliseconds)
  }

  return 0;
}
