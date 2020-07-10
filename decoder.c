
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
#define pressTouch 0
#define releaseTouch 1
#define moveTouch 2
#define clickPoint 3

#define startUid 0x000000e2
#define debugFlag 1

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

    // if (ioctl(fd, EVIOCGVERSION, &version))
    // {
    //     fprintf(stderr, "could not get driver version for %s, %s\n", argv[optind], strerror(errno));
    //     return 1;
    // }

    struct input_event sync; //同步 直接用
    sync.type = 0;
    sync.code = 0;
    sync.value = 0;

    struct input_event set_id; //切换触摸点 修改value再用
    set_id.type = 3;
    set_id.code = 0x2f;
    set_id.value = 0;

    struct input_event pos_x; //X坐标
    pos_x.type = 3;
    pos_x.code = 0x35;
    pos_x.value = 0;

    struct input_event pos_y; //Y坐标
    pos_y.type = 3;
    pos_y.code = 0x36;
    pos_y.value = 0;

    struct input_event defineUID; //声明识别ID 用于消除
    defineUID.type = 3;
    defineUID.code = 0x39;
    defineUID.value = 0;

    struct input_event down; //按下 没有触摸点的时候使用
    down.type = 1;
    down.code = 0x14a;
    down.value = 0x1;

    struct input_event up; //释放 触摸点全部释放的时候使用
    up.type = 1;
    up.code = 0x14a;
    up.value = 0x0;

    int total_pressing_number = 0;
    while (1)
    {
        memset(message, '\0', 64);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
        if (debugFlag)
        {
            printf("%s\n", message);
        }
        if (!strcmp(message, "end"))
            break;
        memset(&event, 0, sizeof(event));
        char *token = strtok(message, " ");
        int type = atoi(token);

        if (type == moveTouch) //移动:  切换ID,X,Y,同步 编码格式 "2 id x y"
        {
            set_id.value = atoi(strtok(NULL, " "));
            write(fd, &set_id, sizeof(set_id));
            pos_x.value = atoi(strtok(NULL, " "));
            write(fd, &pos_x, sizeof(pos_x));
            pos_y.value = atoi(strtok(NULL, " "));
            write(fd, &pos_y, sizeof(pos_y));
            write(fd, &sync, sizeof(sync));
        }
        else if (type == releaseTouch) //释放: 切换ID,uid=-1,同步 编码格式 "1 id"
        {
            total_pressing_number--;
            set_id.value = atoi(strtok(NULL, " "));
            write(fd, &set_id, sizeof(set_id));
            defineUID.value = 0xffffffff;
            write(fd, &defineUID, sizeof(defineUID));
            if (total_pressing_number == 0) //为0 全部释放 btn up
                write(fd, &up, sizeof(up));
            write(fd, &sync, sizeof(sync));
        }
        else if (type == pressTouch)
        { //type == pressTouch  按下： 切换ID，uid=自定义，x，y，同步 编码格式 "0 id x y"
            set_id.value = atoi(strtok(NULL, " "));
            defineUID.value = startUid + set_id.value;
            write(fd, &set_id, sizeof(set_id));
            write(fd, &defineUID, sizeof(defineUID));
            if (total_pressing_number == 0) //为0 则是头一次按下 btn down
                write(fd, &down, sizeof(down));
            pos_x.value = atoi(strtok(NULL, " "));
            write(fd, &pos_x, sizeof(pos_x));
            pos_y.value = atoi(strtok(NULL, " "));
            write(fd, &pos_y, sizeof(pos_y));
            write(fd, &sync, sizeof(sync));
            total_pressing_number++;
        }
        else if (type == clickPoint) //点击一个点 编码格式 3 x y
        {
            set_id.value = 8;
            defineUID.value = startUid + set_id.value;
            write(fd, &set_id, sizeof(set_id));
            write(fd, &defineUID, sizeof(defineUID));
            if (total_pressing_number == 0) //为0 则是头一次按下 btn down
                write(fd, &down, sizeof(down));
            total_pressing_number++;
            pos_x.value = atoi(strtok(NULL, " "));
            write(fd, &pos_x, sizeof(pos_x));
            pos_y.value = atoi(strtok(NULL, " "));
            write(fd, &pos_y, sizeof(pos_y));
            write(fd, &sync, sizeof(sync));
            defineUID.value = 0xffffffff;
            write(fd, &defineUID, sizeof(defineUID));
            total_pressing_number--;
            if (total_pressing_number == 0) //为0 全部释放 btn up
                write(fd, &up, sizeof(up));
            write(fd, &sync, sizeof(sync));
        }
    }
    close(fd);
    close(socket_descriptor);
    return 0;
}