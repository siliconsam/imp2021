#include <stdio.h>

void swapnum(int *i, int *j)
{
  int ii = *i;
  int jj = *j;
  printf("Before_: i is %d and j is %d\n", ii, jj);
  int temp;
  temp = ii;
  ii = jj;
  jj = temp;
  printf(" After_: i is %d and j is %d\n", ii, jj);
  *i = ii;
  *j = jj;
}

int main(void)
{
  int a = 40;
  int b = 20;

  printf("Before: A is %d and B is %d\n", a, b);
  swapnum(&a, &b);
  printf(" After: A is %d and B is %d\n", a, b);
  return 0;
}
