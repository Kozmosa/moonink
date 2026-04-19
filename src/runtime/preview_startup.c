#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

int moonink_preview_startup_check(const char *host, int port) {
  if (port <= 0 || port > 65535) {
    return -2;
  }

  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    return errno ? errno : -1;
  }

  int reuse_addr = 1;
  setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse_addr, sizeof(reuse_addr));

  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t) port);

  if (host == NULL || host[0] == '\0' || strcmp(host, "0.0.0.0") == 0) {
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
  } else if (strcmp(host, "localhost") == 0) {
    if (inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr) != 1) {
      close(sock);
      return -3;
    }
  } else if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
    close(sock);
    return -3;
  }

  if (bind(sock, (struct sockaddr *) &addr, sizeof(addr)) != 0) {
    int bind_errno = errno ? errno : -1;
    close(sock);
    return bind_errno;
  }

  if (listen(sock, 1) != 0) {
    int listen_errno = errno ? errno : -4;
    close(sock);
    return listen_errno;
  }

  close(sock);
  return 0;
}
