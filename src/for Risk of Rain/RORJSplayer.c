#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/input.h>
#include <time.h>
#include <stdint.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <errno.h>
#include <libgen.h>
#include <semaphore.h>
#include <pthread.h>
#include <linux/uinput.h>

static struct uinput_user_dev uinput_dev;
static int uinput_fd;

int creat_user_uinput(void);
int report_key(unsigned int keycode, unsigned int value);

#define DOWN 0x1
#define UP 0x0
#define MOVE_FLAG 0x0
#define RELEASE_FLAG 0x2
#define REQURIE_FLAG 0x1
#define WHEEL_REQUIRE 0X3
#define MOUSE_REQUIRE 0X4
#define KEY_CUSTOM_UP 0x20
#define KEY_CUSTOM_DOWN 0x30

char touch_dev_path[80];
char joystick_dev_path[80];
int joystick_dev = 15;
int touch_fd;                   //触屏的设备文件指针
int Exclusive_mode_flag = 0;    //独占模式标识
int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式
int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int allocatedID_num = 0;

struct input_event joystick_queue[16];
int j_len = 0;

int lt_last = 0, rt_last = 0;
int HAT0X_last = 0, HAT0Y_last = 0;

int js_btn_type[] = {BTN_A, BTN_B, BTN_X, BTN_Y, BTN_SELECT, BTN_START, BTN_TL, BTN_TR, BTN_THUMBL, BTN_THUMBR};
int rorReMap[30];
int key_stause[30];
void BTN_MANAGER(int keyCode, int updown)
{

    if (key_stause[keyCode] == updown)
        return;
    else
        key_stause[keyCode] = updown;
    if (rorReMap[keyCode] != 0)
    {
        report_key(rorReMap[keyCode], updown);
    }
}
int ls_x_val = 0;
int ls_y_val = 0;
int rs_x_val = 0;
int rs_y_val = 0;
int start_UP_DOWN = 0;

//27 左   29右
//左边小于0 右边大于0
void handle_ls_move(int last_ls_x, int last_ls_y)
{
    if (last_ls_x * ls_x_val < 0)
    {
        if (last_ls_x > 0)
        {
            BTN_MANAGER(29, UP);
            BTN_MANAGER(27, DOWN);
        }
        else
        {
            BTN_MANAGER(27, UP);
            BTN_MANAGER(29, DOWN);
        }
    }
    else
    {
        if (last_ls_x == 0 && ls_x_val != 0)
        {
            BTN_MANAGER(ls_x_val > 0 ? 29 : 27, DOWN);
        }
        if (last_ls_x != 0 && ls_x_val == 0)
        {
            BTN_MANAGER(last_ls_x > 0 ? 29 : 27, UP);
        }
    }
    if (last_ls_y * ls_y_val < 0)
    {
        if (last_ls_y > 0)
        {
            BTN_MANAGER(24, UP);
            BTN_MANAGER(26, DOWN);
        }
        else
        {
            BTN_MANAGER(26, UP);
            BTN_MANAGER(24, DOWN);
        }
    }
    else
    {
        if (last_ls_y == 0 && ls_y_val != 0)
        {
            BTN_MANAGER(ls_y_val > 0 ? 24 : 26, DOWN);
        }
        if (last_ls_y != 0 && ls_y_val == 0)
        {
            BTN_MANAGER(last_ls_y > 0 ? 24 : 26, UP);
        }
    }
}
void handel_joystick_queue() // 注意  切换操作也在这里
//然后 范围计算转换 也在这里完成
//扳机按照数值不同 可以映射单独按键 需要记录last值以确定是进入范围还是离开范围
{
    int last_ls_x = ls_x_val;
    int last_ls_y = ls_y_val;
    for (int i = 0; i < j_len - 1; i++)
    {
        if (joystick_queue[i].code == BTN_START)
        {
            start_UP_DOWN = joystick_queue[i].value;
        }
        if (start_UP_DOWN == DOWN && joystick_queue[i].code == BTN_THUMBR && joystick_queue[i].value == UP)
        {
            int tmp = Exclusive_mode_flag;
            Exclusive_mode_flag = no_Exclusive_mode_flag;
            no_Exclusive_mode_flag = tmp;
        }
        if (Exclusive_mode_flag == 1)
        {
            for (int j = 0; j < 10; j++)
            {
                if (joystick_queue[i].code == js_btn_type[j])
                {
                    if (joystick_queue[i].value == UP)
                    {
                        BTN_MANAGER(joystick_queue[i].code - 0x130, UP);
                    }
                    else
                    {
                        BTN_MANAGER(joystick_queue[i].code - 0x130, DOWN);
                    }
                }
            }
            if (joystick_queue[i].code == ABS_HAT0X)
            {
                int val = joystick_queue[i].value;
                if (HAT0X_last == 0) //按下
                {
                    BTN_MANAGER(28 + val, DOWN);
                }
                if (val == 0) //释放
                {
                    BTN_MANAGER(28 + HAT0X_last, UP);
                }
                HAT0X_last = val;
            }
            else if (joystick_queue[i].code == ABS_HAT0Y)
            {
                int val = joystick_queue[i].value;
                if (HAT0Y_last == 0) //按下
                {
                    BTN_MANAGER(25 + val, DOWN);
                }
                if (val == 0) //释放
                {
                    BTN_MANAGER(25 + HAT0Y_last, UP);
                }
                HAT0Y_last = val;
            }
            else if (joystick_queue[i].code == ABS_X)
            {
                ls_x_val = (joystick_queue[i].value - 128) * 2;
            }
            else if (joystick_queue[i].code == ABS_Y)
            {
                ls_y_val = (joystick_queue[i].value - 128) * -2;
            }
            else if (joystick_queue[i].code == ABS_Z)
            {
                rs_y_val = (joystick_queue[i].value - 128) / 8;
            }
            else if (joystick_queue[i].code == ABS_RZ)
            {
                rs_x_val = (joystick_queue[i].value - 128) / -8;
            }
            else if (joystick_queue[i].code == ABS_GAS)
            {
                int val = joystick_queue[i].value;
                if (rt_last > 128 && val <= 128) //回弹
                {
                    BTN_MANAGER(20, UP);
                }
                else if (rt_last <= 128 && val > 128) //按下
                {
                    BTN_MANAGER(20, DOWN);
                }

                if (rt_last > 250 && val <= 250) //回弹
                {
                    BTN_MANAGER(21, UP);
                }
                else if (rt_last <= 250 && val > 250) //按下
                {
                    BTN_MANAGER(21, DOWN);
                }
                rt_last = val;
            }
            else if (joystick_queue[i].code == ABS_BRAKE)
            {
                int val = joystick_queue[i].value;
                if (lt_last > 128 && val <= 128) //回弹
                {
                    BTN_MANAGER(22, UP);
                }
                else if (lt_last <= 128 && val > 128) //按下
                {
                    BTN_MANAGER(22, DOWN);
                }

                if (lt_last > 250 && val <= 250) //回弹
                {
                    BTN_MANAGER(23, UP);
                }
                else if (lt_last <= 250 && val > 250) //按下
                {
                    BTN_MANAGER(23, DOWN);
                }
                lt_last = val;
            }
            if (last_ls_x != ls_x_val || last_ls_y != ls_y_val)
            {
                handle_ls_move(last_ls_x, last_ls_y);
            }
        }
    }
    j_len = 0;
}
int no_Exclusive_mode_JoyStick()
{
    int rcode = 0;
    char joystick_name[256] = "Unknown";
    int joystick_fd = open(joystick_dev_path, O_RDONLY | O_NONBLOCK);
    if (joystick_fd == -1)
    {
        printf("Failed to open JoyStick\n");
        exit(1);
    }
    rcode = ioctl(joystick_fd, EVIOCGNAME(sizeof(joystick_name)), joystick_name);
    printf("Reading From : %s \n", joystick_name);
    struct input_event joystick_event;
    while (no_Exclusive_mode_flag == 1)
        if (read(joystick_fd, &joystick_event, sizeof(joystick_event)) != -1)
        {
            joystick_queue[j_len++] = joystick_event;
            if (joystick_event.type == 0 && joystick_event.code == 0 && joystick_event.value == 0)
                handel_joystick_queue();
        }
    printf("Exiting.\n");
    close(joystick_fd);
    return 0;
}

int Exclusive_mode_JoyStick()
{
    int rcode;
    char joystick_name[256] = "Unknown";
    int joystick_dev_fd = open(joystick_dev_path, O_RDONLY | O_NONBLOCK);
    if (joystick_dev_fd == -1)
    {
        printf("Failed to open DEV.\n");
        exit(1);
    }
    rcode = ioctl(joystick_dev_fd, EVIOCGNAME(sizeof(joystick_name)), joystick_name);
    printf("Reading From : %s \n", joystick_name);
    printf("Getting exclusive access: ");
    rcode = ioctl(joystick_dev_fd, EVIOCGRAB, 1);
    printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
    struct input_event joystick_event;

    while (Exclusive_mode_flag == 1)
    {
        if (read(joystick_dev_fd, &joystick_event, sizeof(joystick_event)) != -1)
        {
            joystick_queue[j_len++] = joystick_event;
            if (joystick_event.type == 0 && joystick_event.code == 0 && joystick_event.value == 0)
                handel_joystick_queue();
        }
    }
    printf("Exiting.\n");
    rcode = ioctl(joystick_dev_fd, EVIOCGRAB, 1);
    close(joystick_dev_fd);
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

int main(int argc, char *argv[]) //触屏设备号 键盘设备号 鼠标设备号 mapper映射文件路径 首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{

    int ret = 0;
    ret = creat_user_uinput();
    if (ret < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        return -1; //error process.
    }

    int joystick_dev_num = atoi(argv[1]);

    sprintf(joystick_dev_path, "/dev/input/event%d", joystick_dev_num);
    printf("Joystick_dev_path:%s\n", joystick_dev_path);

    rorReMap[11] = 212;
    rorReMap[0] = 32;
    rorReMap[1] = 45;
    rorReMap[3] = 31;
    rorReMap[4] = 17;
    rorReMap[6] = 21;
    rorReMap[22] = 21;
    rorReMap[7] = 44;
    rorReMap[20] = 44;
    rorReMap[24] = 103;
    rorReMap[26] = 108;
    rorReMap[27] = 105;
    rorReMap[29] = 106;
    rorReMap[10] = 20;
    while (1)
    {
        no_Exclusive_mode_JoyStick();
        Exclusive_mode_JoyStick();
    }
}
