#include <stdint.h>
#include <time.h>

int64_t moonink_current_unix_second(void) {
  return (int64_t)time(NULL);
}
