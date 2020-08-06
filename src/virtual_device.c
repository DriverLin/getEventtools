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
int report_key(unsigned int type, unsigned int keycode, unsigned int value);

int reveive_from_UDP(int port)
{
    int sin_len;
    char message[8];
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
        memset(message, '\0', 8);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
        if (!strcmp(message, "end"))
            return 0;
        int code = atoi(message);
        if (code > 0)
        {
            report_key(EV_KEY, code, 0);
        }
        else
        {
            report_key(EV_KEY, code * -1, 1);
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
    uinput_dev.id.bustype = BUS_VIRTUAL;

    ioctl(uinput_fd, UI_SET_EVBIT, EV_SYN);
    ioctl(uinput_fd, UI_SET_EVBIT, EV_KEY);
    ioctl(uinput_fd, UI_SET_EVBIT, EV_MSC);

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

int report_key(unsigned int type, unsigned int keycode, unsigned int value)
{
    // struct input_event EV_MSC_EVENT = {.type = EV_MSC, .code = MSC_SCAN, .value = keycode};
    struct input_event EV_KEY_EVENT = {.type = EV_KEY, .code = keycode, .value = value};
    struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    // write(uinput_fd, &EV_MSC_EVENT, sizeof(struct input_event));
    write(uinput_fd, &EV_KEY_EVENT, sizeof(struct input_event));
    write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
    return 0;
}

// int repreport_mouse(unsigned int x, unsigned int y)
// {
//     struct input_event REL_X_EVENT = {.type = EV_REL, .code = REL_X, .value = x};
//     struct input_event REL_Y_EVENT = {.type = EV_REL, .code = REL_Y, .value = y};
//     struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
//     write(uinput_fd, &REL_X_EVENT, sizeof(struct input_event));
//     write(uinput_fd, &REL_Y_EVENT, sizeof(struct input_event));
//     write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
//     return 0;
// }
