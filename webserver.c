#include <stdio.h>
#include "uv.h"

int main() {
  uv_init();
  uv_loop_t* loop = uv_default_loop();

  printf("Hello World\n");
  
  uv_run(loop);
}
