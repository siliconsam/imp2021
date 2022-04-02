#include <signal.h>
#include <stdio.h>
#include <stdlib.h>

static void catch_function(int signo) {
    puts("SIGINT Interactive attention signal caught.");
}

int main(void) {
    printf("EXIT_FAILURE=%d.\n", EXIT_FAILURE);
    printf("EXIT_SUCCESS=%d.\n", EXIT_SUCCESS);
    printf("SIG_ERR=%d.\n", (int)SIG_ERR);

    // Set above function as signal handler for the SIGINT signal:
    if (signal(SIGINT, catch_function) == SIG_ERR) {
        fputs("An error occurred while setting a signal handler.\n", stderr);
        return EXIT_FAILURE;
    }
    puts("Raising the interactive attention signal.");
    if (raise(SIGINT) != 0) {
        fputs("Error raising the signal.\n", stderr);
        return EXIT_FAILURE;
    }
    puts("Exiting.");
    return EXIT_SUCCESS;
    // exiting after raising signal
}
