#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <sys/socket.h>
#include <arpa/inet.h>

int fd;

int reveive_from_UDP(int port)
{
    int sin_len;
    unsigned char message[6];
    int socket_descriptor;
    struct sockaddr_in sin;
    bzero(&sin, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = htonl(INADDR_ANY);
    sin.sin_port = htons(port);
    sin_len = sizeof(sin);
    socket_descriptor = socket(AF_INET, SOCK_DGRAM, 0);
    bind(socket_descriptor, (struct sockaddr *)&sin, sizeof(sin));
    while (1)
    {
        memset(message, '\0', 6);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
        if (!strcmp(message, "end")) //发送END  结束
            return 0;
        int code = message[0] * 0x100 + message[1];
        switch (code)
        {
        case ABS_Z: //包括 ZR : code,x,y  0~65535
        {
            struct input_event X_EVENT = {.type = EV_ABS, .code = REL_Z, .value = message[2] * 0x100 + message[3]};
            struct input_event Y_EVENT = {.type = EV_ABS, .code = REL_RZ, .value = message[4] * 0x100 + message[5]};
            struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
            write(fd, &X_EVENT, sizeof(struct input_event));
            write(fd, &Y_EVENT, sizeof(struct input_event));
            write(fd, &SYNC_EVENT, sizeof(struct input_event));
            break;
        }
        case ABS_X: //包括Y: code,x,y  0~65535
        {
            struct input_event X_EVENT = {.type = EV_ABS, .code = REL_X, .value = message[2] * 0x100 + message[3]};
            struct input_event Y_EVENT = {.type = EV_ABS, .code = REL_Y, .value = message[4] * 0x100 + message[5]};
            struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
            write(fd, &X_EVENT, sizeof(struct input_event));
            write(fd, &Y_EVENT, sizeof(struct input_event));
            write(fd, &SYNC_EVENT, sizeof(struct input_event));
            break;
        }
        case ABS_BRAKE: //: code,value 0~65535
        case ABS_GAS:
        {
            struct input_event VALUE = {.type = EV_ABS, .code = code, .value = message[2] * 0x100 + message[3]};
            struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
            write(fd, &VALUE, sizeof(struct input_event));
            write(fd, &SYNC_EVENT, sizeof(struct input_event));
            break;
        }
        case ABS_HAT0X:
        case ABS_HAT0Y: // code,value 0~2
        {
            struct input_event VALUE = {.type = EV_ABS, .code = code, .value = message[3] - 1};
            struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
            write(fd, &VALUE, sizeof(struct input_event));
            write(fd, &SYNC_EVENT, sizeof(struct input_event));
            break;
        }
        default: //KEY_EVENT code,value 0|1
        {
            struct input_event EV_KEY_EVENT = {.type = EV_KEY, .code = code, .value = message[3]};
            struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
            write(fd, &EV_KEY_EVENT, sizeof(struct input_event));
            write(fd, &SYNC_EVENT, sizeof(struct input_event));
            break;
        }
        }
    }
    close(socket_descriptor);
    return 0;
}

int main(void)
{
    fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK); //opening of uinput
    if (fd < 0)
    {
        printf("Opening of uinput failed!\n");
        return 1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_KEY);       //setting Gamepad keys
    ioctl(fd, UI_SET_KEYBIT, BTN_GAMEPAD); //A
    ioctl(fd, UI_SET_KEYBIT, BTN_EAST);    //B
    ioctl(fd, UI_SET_KEYBIT, BTN_NORTH);   //X
    ioctl(fd, UI_SET_KEYBIT, BTN_WEST);    //Y
    ioctl(fd, UI_SET_KEYBIT, BTN_TL);      //LB
    ioctl(fd, UI_SET_KEYBIT, BTN_TR);      //RB
    ioctl(fd, UI_SET_KEYBIT, BTN_SELECT);  //SELECT
    ioctl(fd, UI_SET_KEYBIT, BTN_START);   //START
    ioctl(fd, UI_SET_KEYBIT, BTN_THUMBL);  //LS
    ioctl(fd, UI_SET_KEYBIT, BTN_THUMBR);  //RS

    ioctl(fd, UI_SET_EVBIT, EV_ABS);     //setting Gamepad thumbsticks
    ioctl(fd, UI_SET_ABSBIT, ABS_X);     //X
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);     //Y
    ioctl(fd, UI_SET_ABSBIT, ABS_Z);     //RX
    ioctl(fd, UI_SET_ABSBIT, ABS_RZ);    //RY
    ioctl(fd, UI_SET_ABSBIT, ABS_BRAKE); //LT
    ioctl(fd, UI_SET_ABSBIT, ABS_GAS);   //RT
    ioctl(fd, UI_SET_ABSBIT, ABS_HAT0X); //RT
    ioctl(fd, UI_SET_ABSBIT, ABS_HAT0Y); //RT

    struct uinput_user_dev uidev; //setting the default settings of Gamepad
    memset(&uidev, 0, sizeof(uidev));
    snprintf(uidev.name, UINPUT_MAX_NAME_SIZE, "Xbox Wireless Controller"); //Name of Gamepad
    uidev.id.bustype = BUS_USB;
    uidev.id.vendor = 0x3;
    uidev.id.product = 0x3;
    uidev.id.version = 2;

    uidev.absmax[ABS_X] = 0xffff; //Parameters of thumbsticks
    uidev.absmin[ABS_X] = 0;

    uidev.absmax[ABS_Y] = 0xffff;
    uidev.absmin[ABS_Y] = 0;

    uidev.absmax[ABS_Z] = 0xffff;
    uidev.absmin[ABS_Z] = 0;

    uidev.absmax[ABS_RZ] = 0xffff;
    uidev.absmin[ABS_RZ] = 0;

    uidev.absmax[ABS_BRAKE] = 0x3ff;
    uidev.absmin[ABS_BRAKE] = 0;

    uidev.absmax[ABS_GAS] = 0x3ff;
    uidev.absmin[ABS_GAS] = 0;

    uidev.absmax[ABS_HAT0X] = 1;
    uidev.absmin[ABS_HAT0X] = -1;

    uidev.absmax[ABS_HAT0Y] = 1;
    uidev.absmin[ABS_HAT0Y] = -1;

    if (write(fd, &uidev, sizeof(uidev)) < 0) //writing settings
    {
        printf("error: write");
        return 1;
    }

    if (ioctl(fd, UI_DEV_CREATE) < 0) //writing ui dev create
    {
        printf("error: ui_dev_create");
        return 1;
    }

    reveive_from_UDP(8848);

    if (ioctl(fd, UI_DEV_DESTROY) < 0)
    {
        printf("error: ioctl");
        return 1;
    }
    close(fd);
    return 0;
}
