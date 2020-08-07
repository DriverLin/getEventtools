#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <linux/input.h>
#include <linux/uinput.h>

int main(void)
{
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK); //opening of uinput
    if (fd < 0)
    {
        printf("Opening of uinput failed!\n");
        return 1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_KEY); //setting Gamepad keys
    ioctl(fd, UI_SET_KEYBIT, BTN_A);
    ioctl(fd, UI_SET_KEYBIT, BTN_B);
    ioctl(fd, UI_SET_KEYBIT, BTN_X);
    ioctl(fd, UI_SET_KEYBIT, BTN_Y);
    ioctl(fd, UI_SET_KEYBIT, BTN_TL);
    ioctl(fd, UI_SET_KEYBIT, BTN_TR);
    ioctl(fd, UI_SET_KEYBIT, BTN_TL2);
    ioctl(fd, UI_SET_KEYBIT, BTN_TR2);
    ioctl(fd, UI_SET_KEYBIT, BTN_START);
    ioctl(fd, UI_SET_KEYBIT, BTN_SELECT);
    ioctl(fd, UI_SET_KEYBIT, BTN_THUMBL);
    ioctl(fd, UI_SET_KEYBIT, BTN_THUMBR);
    ioctl(fd, UI_SET_KEYBIT, BTN_DPAD_UP);
    ioctl(fd, UI_SET_KEYBIT, BTN_DPAD_DOWN);
    ioctl(fd, UI_SET_KEYBIT, BTN_DPAD_LEFT);
    ioctl(fd, UI_SET_KEYBIT, BTN_DPAD_RIGHT);

    ioctl(fd, UI_SET_EVBIT, EV_ABS); //setting Gamepad thumbsticks
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    ioctl(fd, UI_SET_ABSBIT, ABS_RX);
    ioctl(fd, UI_SET_ABSBIT, ABS_RY);

    struct uinput_user_dev uidev; //setting the default settings of Gamepad
    memset(&uidev, 0, sizeof(uidev));
    snprintf(uidev.name, UINPUT_MAX_NAME_SIZE, "xbox controler"); //Name of Gamepad
    uidev.id.bustype = BUS_USB;
    uidev.id.vendor = 0x3;
    uidev.id.product = 0x3;
    uidev.id.version = 2;

    uidev.absmax[ABS_X] = 512; //Parameters of thumbsticks
    uidev.absmin[ABS_X] = -512;
    uidev.absfuzz[ABS_X] = 0;
    uidev.absflat[ABS_X] = 15;

    uidev.absmax[ABS_Y] = 512;
    uidev.absmin[ABS_Y] = -512;
    uidev.absfuzz[ABS_Y] = 0;
    uidev.absflat[ABS_Y] = 15;

    uidev.absmax[ABS_RX] = 512;
    uidev.absmin[ABS_RX] = -512;
    uidev.absfuzz[ABS_RX] = 0;
    uidev.absflat[ABS_RX] = 16;

    uidev.absmax[ABS_RY] = 512;
    uidev.absmin[ABS_RY] = -512;
    uidev.absfuzz[ABS_RY] = 0;
    uidev.absflat[ABS_RY] = 16;

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

    struct input_event ev;
    unsigned char toggle = 0;
    // while (1)
    // {
    //     memset(&ev, 0, sizeof(struct input_event)); //setting the memory for event
    //     ev.type = EV_KEY;
    //     ev.code = BTN_X;
    //     ev.value = !toggle;
    //     toggle = !toggle;
    //     if (write(fd, &ev, sizeof(struct input_event)) < 0) //writing the key change
    //     {
    //         printf("error: key-write");
    //         return 1;
    //     }

    //     memset(&ev, 0, sizeof(struct input_event)); //setting the memory for event
    //     ev.type = EV_ABS;
    //     ev.code = ABS_X;
    //     ev.value = toggle == 1 ? 256 : 0;
    //     if (write(fd, &ev, sizeof(struct input_event)) < 0) //writing the thumbstick change
    //     {
    //         printf("error: thumbstick-write");
    //         return 1;
    //     }

    //     memset(&ev, 0, sizeof(struct input_event));
    //     ev.type = EV_SYN;
    //     ev.code = SYN_REPORT;
    //     ev.value = 0;
    //     if (write(fd, &ev, sizeof(struct input_event)) < 0) //writing the sync report
    //     {
    //         printf("error: sync-report");
    //         return 1;
    //     }
    // }

    sleep(1);
    int buttons[] = {
        BTN_A,
        BTN_B,
        BTN_X,
        BTN_Y,
        BTN_TL,
        BTN_TR,
        BTN_SELECT,
        BTN_START,
        BTN_DPAD_UP,
        BTN_DPAD_DOWN,
        BTN_DPAD_LEFT,
        BTN_DPAD_RIGHT};

    for (int i = 0; i < sizeof(buttons) / sizeof(int); i++)
    {
        struct input_event a_down = {.type = EV_KEY, .code = buttons[i], .value = 1};
        struct input_event a_up = {.type = EV_KEY, .code = buttons[i], .value = 0};
        struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
        write(fd, &a_down, sizeof(struct input_event));
        write(fd, &SYNC_EVENT, sizeof(struct input_event));
        sleep(1);
        write(fd, &a_up, sizeof(struct input_event));
        write(fd, &SYNC_EVENT, sizeof(struct input_event));
        sleep(1);
    }

    if (ioctl(fd, UI_DEV_DESTROY) < 0)
    {
        printf("error: ioctl");
        return 1;
    }

    close(fd);
    return 0;
}