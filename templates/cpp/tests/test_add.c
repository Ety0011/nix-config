#undef NDEBUG // keep assert() in every build type
#include "add.h"

#include <assert.h>

int main(void) {
  assert(add(2, 3) == 5);
  return 0;
}
