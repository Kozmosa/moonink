#include <errno.h>
#include <signal.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

int moonink_exec_shell_command(const char *command) {
  execl("/bin/sh", "sh", "-c", command, (char *)NULL);
  return errno;
}

int moonink_spawn_shell_command(const char *command) {
  pid_t pid = fork();
  if (pid < 0) {
    return -errno;
  }
  if (pid == 0) {
    prctl(PR_SET_PDEATHSIG, SIGTERM);
    execl("/bin/sh", "sh", "-c", command, (char *)NULL);
    _exit(127);
  }
  return (int)pid;
}

int moonink_poll_child_process(int pid) {
  int status = 0;
  pid_t waited = waitpid((pid_t)pid, &status, WNOHANG);
  if (waited == 0) {
    return 0;
  }
  if (waited < 0) {
    return -errno;
  }
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status) + 1;
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return 1;
}

int moonink_terminate_child_process(int pid) {
  if (kill((pid_t)pid, SIGTERM) == 0) {
    return 0;
  }
  if (errno == ESRCH) {
    return 0;
  }
  return errno;
}

void moonink_sleep_millis(int milliseconds) {
  if (milliseconds <= 0) {
    return;
  }
  struct timespec req;
  req.tv_sec = milliseconds / 1000;
  req.tv_nsec = (long)(milliseconds % 1000) * 1000000L;
  nanosleep(&req, NULL);
}
