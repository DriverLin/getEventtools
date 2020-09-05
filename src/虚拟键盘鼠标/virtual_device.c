#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <linux/uinput.h>
#include <linux/input.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#define KEY_CUSTOM_UP 0x20
#define KEY_CUSTOM_DOWN 0x30

static struct uinput_user_dev uinput_dev;
static int uinput_fd;

int creat_user_uinput(void);
int report_key(unsigned int keycode, unsigned int value);

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

int main(int argc, char *argv[])
{
    int ret = 0;
    ret = creat_user_uinput();
    if (ret < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        return -1; //error process.
    }
    sleep(1);
    reveive_from_UDP(8848);
    close(uinput_fd);

    return 0;
}
int creat_user_uinput(void)
{
    int i;
    int ret = 0;

    uinput_fd = open("/dev/uinput", O_RDWR | O_NDELAY);
    if (uinput_fd < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        return -1; //error process.
    }
    //to set uinput dev
    memset(&uinput_dev, 0, sizeof(struct uinput_user_dev));
    snprintf(uinput_dev.name, UINPUT_MAX_NAME_SIZE, "uinput-custom-dev");
    uinput_dev.id.version = 1;
    uinput_dev.id.bustype = BUS_USB;
    uinput_dev.id.vendor = 0x1234;
    uinput_dev.id.product = 0x5678;

    ioctl(uinput_fd, UI_SET_EVBIT, EV_SYN);
    ioctl(uinput_fd, UI_SET_EVBIT, EV_KEY);
    ioctl(uinput_fd, UI_SET_EVBIT, EV_MSC);
    ioctl(uinput_fd, UI_SET_EVBIT, EV_REL);
    ioctl(uinput_fd, UI_SET_RELBIT, REL_X);
    ioctl(uinput_fd, UI_SET_RELBIT, REL_Y);

    for (int i = 0x110; i < 0x117; i++)
    {
        ioctl(uinput_fd, UI_SET_KEYBIT, i);
    }

    for (i = 0; i < 256; i++)
    {
        ioctl(uinput_fd, UI_SET_KEYBIT, i);
    }
    ioctl(uinput_fd, UI_SET_MSCBIT, KEY_CUSTOM_UP);
    ioctl(uinput_fd, UI_SET_MSCBIT, KEY_CUSTOM_DOWN);
    ret = write(uinput_fd, &uinput_dev, sizeof(struct uinput_user_dev));
    if (ret < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        return ret; //error process.
    }

    ret = ioctl(uinput_fd, UI_DEV_CREATE);
    if (ret < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        close(uinput_fd);
        return ret; //error process.
    }
}

int report_key(unsigned int keycode, unsigned int value)
{
    // struct input_event EV_MSC_EVENT = {.type = EV_MSC, .code = MSC_SCAN, .value = keycode};
    struct input_event EV_KEY_EVENT = {.type = EV_KEY, .code = keycode, .value = value};
    struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    // write(uinput_fd, &EV_MSC_EVENT, sizeof(struct input_event));
    write(uinput_fd, &EV_KEY_EVENT, sizeof(struct input_event));
    write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
    return 0;
}

int repreport_mouse_move(unsigned int x, unsigned int y)
{
    // printf("%d,%d\n", x, y);
    struct input_event REL_X_EVENT = {.type = EV_REL, .code = REL_X, .value = x};
    struct input_event REL_Y_EVENT = {.type = EV_REL, .code = REL_Y, .value = y};
    struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    write(uinput_fd, &REL_X_EVENT, sizeof(struct input_event));
    write(uinput_fd, &REL_Y_EVENT, sizeof(struct input_event));
    write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
    return 0;
}
