#include <errno.h>
#include <unistd.h>

int moonink_exec_shell_command(const char *command) {
  execl("/bin/sh", "sh", "-c", command, (char *)NULL);
  return errno;
}
