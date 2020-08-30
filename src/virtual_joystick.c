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
int reveive_from_UDP(int port)
{
    int sin_len;
    char message[16];
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
        memset(message, '\0', 16);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
        // printf("%s\n", message);
        if (!strcmp(message, "end")) //发送END  结束
            return 0;
        int code = atoi(message); //编码格式  移动/按下/释放- valueX-valueY / CODE
        int type = code / 100000000;
        code %= 100000000;
        switch (type)
        {
        case 0: //移动
        {
            int mouse_x = code / 10000;
            int mouse_y = code % 10000;
            if (mouse_x > 5000)
            {
                mouse_x -= 10000;
            }
            if (mouse_y > 5000)
            {
                mouse_y -= 10000;
            }
            repreport_mouse_move(mouse_x, mouse_y);
            // printf("移动,x=%d,%y=%d\n", mouse_x, mouse_y);
            break;
        }
        case 1:
        {
            report_key(code, 1);
            // printf("按下,%d\n", code);
            break;
        }
        case 2:
        {
            report_key(code, 0);
            // printf("释放,%d\n", code);
            break;
        }
        default:
            break;
        }
    }
    close(socket_descriptor);
    return 0;
}
int fd;
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
    ioctl(fd, UI_SET_KEYBIT, KEY_BACK);    //BACL
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

int report_key(unsigned int keycode, unsigned int value)
{
    // struct input_event EV_KEY_EVENT = {.type = EV_KEY, .code = keycode, .value = value};
    // struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    // write(fd, &EV_KEY_EVENT, sizeof(struct input_event));
    // write(fd, &SYNC_EVENT, sizeof(struct input_event));
    return 0;
}

int repreport_mouse_move(unsigned int x, unsigned int y)
{
    struct input_event REL_X_EVENT = {.type = EV_ABS, .code = ABS_Z, .value = x * 0xff + 0xffff / 2};
    struct input_event REL_Y_EVENT = {.type = EV_ABS, .code = ABS_RZ, .value = y * 0xff + 0xffff / 2};
    struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    write(fd, &REL_X_EVENT, sizeof(struct input_event));
    write(fd, &REL_Y_EVENT, sizeof(struct input_event));
    write(fd, &SYNC_EVENT, sizeof(struct input_event));
    return 0;
}
