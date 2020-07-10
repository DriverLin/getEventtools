
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

// struct input_event
// {
//     struct timeval time;
//     __u16 type;
//     __u16 code;
//     __s32 value;
// };
int reveive_from_UDP(int port, char *buffer)
{
    int sin_len;
    char message[1024];
    int socket_descriptor;
    struct sockaddr_in sin;
    bzero(&sin, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = htonl(INADDR_ANY);
    sin.sin_port = htons(port);
    sin_len = sizeof(sin);
    socket_descriptor = socket(AF_INET, SOCK_DGRAM, 0);
    bind(socket_descriptor, (struct sockaddr *)&sin, sizeof(sin));
    recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
    memcpy(buffer, message, 1024);
    close(socket_descriptor);
    return 0;
}

int udp_r()
{
    char buffer[1024];
    while (1)
    {
        reveive_from_UDP(8848, buffer);
        if (!strcmp(buffer, "end"))
            break;
        printf("%s\n", buffer);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    int sin_len;
    char message[64];
    int socket_descriptor;
    struct sockaddr_in sin;
    bzero(&sin, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = htonl(INADDR_ANY);
    sin.sin_port = htons(8848);
    sin_len = sizeof(sin);
    socket_descriptor = socket(AF_INET, SOCK_DGRAM, 0);
    bind(socket_descriptor, (struct sockaddr *)&sin, sizeof(sin));
    struct input_event event;
    int fd;
    ssize_t ret;
    int version;
    fd = open(argv[1], O_RDWR);
    if (fd < 0)
    {
        fprintf(stderr, "could not open %s, %s\n", argv[optind], strerror(errno));
        return 1;
    }
    if (ioctl(fd, EVIOCGVERSION, &version))
    {
        fprintf(stderr, "could not get driver version for %s, %s\n", argv[optind], strerror(errno));
        return 1;
    }
    while (1)
    {
        memset(message, '\0', 64);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
        if (!strcmp(message, "end"))
            break;
        memset(&event, 0, sizeof(event));
        char *token = strtok(message, " ");
        event.type = atoi(token);
        token = strtok(NULL, " ");
        event.code = atoi(token);
        token = strtok(NULL, " ");
        event.value = atoi(token);
        printf("type = %d\n", event.type);
        printf("code = %d\n", event.code);
        printf("value = %d\n", event.value);
        ret = write(fd, &event, sizeof(event));
        if (ret < (ssize_t)sizeof(event))
        {
            fprintf(stderr, "write event failed, %s\n", strerror(errno));
            return -1;
        }
    }
    close(socket_descriptor);
    return 0;
}