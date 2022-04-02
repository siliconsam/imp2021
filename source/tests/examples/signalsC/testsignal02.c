#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <Windows.h>

void sig_handler(int signum){

  //Return type of the handler function should be void
  printf("\nInside handler function\n");
}

int main(){
  signal(SIGINT,sig_handler); // Register signal handler
  for(int i=1;;i++){    //Infinite loop
    printf("%d : Inside main function\n",i);
    Sleep(10);  // Delay for 1 second
  }
  return 0;
}