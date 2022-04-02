#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <Windows.h>

int x = 0;

void sig_handler(int signum){
  x++;
  printf("\nInside handler function\n");
  if (x==4)
  {
    signal(SIGINT,SIG_DFL);   // Re Register signal handler for default action
  }
  else
  {
    signal(SIGINT,sig_handler); // Register signal handler
  }
}

int main(){
  signal(SIGINT,sig_handler); // Register signal handler
  for(int i=1;;i++){    //Infinite loop
    printf("%d : Inside main function\n",i);
    Sleep(20);  // Delay for 20 second
  }
  return 0;
}
