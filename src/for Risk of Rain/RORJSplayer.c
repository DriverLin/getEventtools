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

int js_btn_type[] = {BTN_A, BTN_B, BTN_X, BTN_Y, KEY_BACK, BTN_SELECT, BTN_START, BTN_TL, BTN_TR, BTN_THUMBL, BTN_THUMBR};
int rorReMap[30];
int key_stause[30];

int ABS_X_RANGE, ABS_Y_RANGE, ABS_Z_RANGE, ABS_RZ_RANGE, ABS_GAS_RANGE, ABS_BRAKE_RANGE; //线性摇杆范围
int ABS_X_MID, ABS_Y_MID, ABS_Z_MID, ABS_RZ_MID, ABS_GAS_MID, ABS_BRAKE_MID;

int deadband = 8;
void BTN_MANAGER(int keyCode, int updown)
{
    // printf("[%d,%d]\n", keyCode, updown);
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

//27 左   29右
//左边小于0 右边大于0
void handle_ls_move(int last_ls_x, int last_ls_y)
{
    // printf("%d,%d\n", ls_x_val, ls_y_val);
    if (last_ls_x * ls_x_val < 0)
    {
        if (last_ls_x > 0)
        {
            BTN_MANAGER(27, UP);
            BTN_MANAGER(29, DOWN);
        }
        else
        {
            BTN_MANAGER(29, UP);
            BTN_MANAGER(27, DOWN);
        }
    }
    else
    {
        if (last_ls_x == 0 && ls_x_val != 0)
        {
            BTN_MANAGER(ls_x_val > 0 ? 27 : 29, DOWN);
        }
        if (last_ls_x != 0 && ls_x_val == 0)
        {
            BTN_MANAGER(last_ls_x > 0 ? 27 : 29, UP);
        }
    }
    if (last_ls_y * ls_y_val < 0)
    {
        if (last_ls_y > 0)
        {
            BTN_MANAGER(26, UP);
            BTN_MANAGER(24, DOWN);
        }
        else
        {
            BTN_MANAGER(24, UP);
            BTN_MANAGER(26, DOWN);
        }
    }
    else
    {
        if (last_ls_y == 0 && ls_y_val != 0)
        {
            BTN_MANAGER(ls_y_val > 0 ? 26 : 24, DOWN);
        }
        if (last_ls_y != 0 && ls_y_val == 0)
        {
            BTN_MANAGER(last_ls_y > 0 ? 26 : 24, UP);
        }
    }
}
int select_UP_DOWN = 0;
void handel_joystick_queue() // 注意  切换操作也在这里
//然后 范围计算转换 也在这里完成
//扳机按照数值不同 可以映射单独按键 需要记录last值以确定是进入范围还是离开范围
{
    int last_ls_x = ls_x_val;
    int last_ls_y = ls_y_val;
    for (int i = 0; i < j_len - 1; i++)
    {
        if (joystick_queue[i].code == KEY_BACK || joystick_queue[i].code == BTN_SELECT)
        {
            select_UP_DOWN = joystick_queue[i].value;
        }
        if (select_UP_DOWN == DOWN && joystick_queue[i].code == BTN_THUMBR && joystick_queue[i].value == UP)
        {
            int tmp = Exclusive_mode_flag;
            Exclusive_mode_flag = no_Exclusive_mode_flag;
            no_Exclusive_mode_flag = tmp;
        }
        if (Exclusive_mode_flag == 1)
        {
            for (int j = 0; j < 11; j++)
            {
                if (joystick_queue[i].code == js_btn_type[j])
                {
                    int keycode = joystick_queue[i].code == KEY_BACK ? BTN_SELECT : joystick_queue[i].code;
                    if (joystick_queue[i].value == UP)
                    {
                        BTN_MANAGER(keycode - 0x130, UP);
                    }
                    else
                    {
                        BTN_MANAGER(keycode - 0x130, DOWN);
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
            else if (joystick_queue[i].code == ABS_Y) //横屏 XY互换了 做其他作用记得换回来
            {
                ls_y_val = (joystick_queue[i].value - ABS_Y_MID);
                if (ls_y_val < ABS_Y_RANGE / deadband && ls_y_val > -1 * ABS_Y_RANGE / deadband) //死区 1/16
                    ls_y_val = 0;
            }
            else if (joystick_queue[i].code == ABS_X)
            {
                ls_x_val = (ABS_X_MID - joystick_queue[i].value);
                if (ls_x_val < ABS_X_RANGE / deadband && ls_x_val > -1 * ABS_X_RANGE / deadband) //死区 1/16
                    ls_x_val = 0;
            }
            else if (joystick_queue[i].code == ABS_Z)
            {
                rs_x_val = (ABS_Z_MID - joystick_queue[i].value);
                if (rs_x_val < ABS_Z_RANGE / deadband && rs_x_val > -1 * ABS_Z_RANGE / deadband) //死区 1/16
                    rs_x_val = 0;
            }
            else if (joystick_queue[i].code == ABS_RZ)
            {
                rs_y_val = (joystick_queue[i].value - ABS_RZ_MID);
                if (rs_y_val < ABS_RZ_RANGE / deadband && rs_y_val > -1 * ABS_RZ_RANGE / deadband) //死区 1/16
                    rs_y_val = 0;
            }
            else if (joystick_queue[i].code == ABS_GAS)
            {
                int val = joystick_queue[i].value;
                if (rt_last > ABS_GAS_MID && val <= ABS_GAS_MID) //回弹
                {
                    BTN_MANAGER(20, UP);
                }
                else if (rt_last <= ABS_GAS_MID && val > ABS_GAS_MID) //按下
                {
                    BTN_MANAGER(20, DOWN);
                }

                if (rt_last > (ABS_GAS_MID + ABS_GAS_RANGE / 2 - 10) && val <= (ABS_GAS_MID + ABS_GAS_RANGE / 2 - 10)) //回弹
                {
                    BTN_MANAGER(21, UP);
                }
                else if (rt_last <= (ABS_GAS_MID + ABS_GAS_RANGE / 2 - 10) && val > (ABS_GAS_MID + ABS_GAS_RANGE / 2 - 10)) //按下
                {
                    BTN_MANAGER(21, DOWN);
                }
                rt_last = val;
            }
            else if (joystick_queue[i].code == ABS_BRAKE)
            {
                int val = joystick_queue[i].value;
                if (lt_last > ABS_BRAKE_MID && val <= ABS_BRAKE_MID) //回弹
                {
                    BTN_MANAGER(22, UP);
                }
                else if (lt_last <= ABS_BRAKE_MID && val > ABS_BRAKE_MID) //按下
                {
                    BTN_MANAGER(22, DOWN);
                }

                if (lt_last > (ABS_BRAKE_MID + ABS_BRAKE_RANGE / 2 - 10) && val <= (ABS_BRAKE_MID + ABS_BRAKE_RANGE / 2 - 10)) //回弹
                {
                    BTN_MANAGER(23, UP);
                }
                else if (lt_last <= (ABS_BRAKE_MID + ABS_BRAKE_RANGE / 2 - 10) && val > (ABS_BRAKE_MID + ABS_BRAKE_RANGE / 2 - 10)) //按下
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
    return 0;
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

int getABSRange(int fd)
{
    uint8_t *bits = NULL;
    ssize_t bits_size = 0;
    const char *label;
    int i, j, k;
    int res, res2;
    struct label *bit_labels;
    const char *bit_label;
    for (i = EV_KEY; i <= EV_MAX; i++)
    { // skip EV_SYN since we cannot query its available codes
        int count = 0;
        while (1)
        {
            res = ioctl(fd, EVIOCGBIT(i, bits_size), bits);
            if (res < bits_size)
                break;
            bits_size = res + 16;
            bits = realloc(bits, bits_size * 2);
            if (bits == NULL)
            {
                fprintf(stderr, "failed to allocate buffer of size %d\n", (int)bits_size);
                return 1;
            }
        }
        res2 = 0;
        for (j = 0; j < res; j++)
        {
            for (k = 0; k < 8; k++)
                if (bits[j] & 1 << k)
                {
                    int ABS_ID = j * 8 + k;
                    if (i == EV_ABS)
                    {
                        struct input_absinfo abs;
                        if (ioctl(fd, EVIOCGABS(j * 8 + k), &abs) == 0)
                        {
                            if (ABS_ID == ABS_X)
                            {
                                ABS_X_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_X_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            else if (ABS_ID == ABS_Y)
                            {
                                ABS_Y_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_Y_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            else if (ABS_ID == ABS_Z)
                            {
                                ABS_Z_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_Z_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            else if (ABS_ID == ABS_RZ)
                            {
                                ABS_RZ_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_RZ_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            else if (ABS_ID == ABS_GAS)
                            {
                                ABS_GAS_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_GAS_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            else if (ABS_ID == ABS_BRAKE)
                            {
                                ABS_BRAKE_RANGE = abs.maximum + 1 - abs.minimum;
                                ABS_BRAKE_MID = (abs.maximum + 1 - abs.minimum) / 2;
                            }
                            printf("%04x: value %d, min %d, max %d, fuzz %d, flat %d, resolution %d\n", ABS_ID, abs.value, abs.minimum, abs.maximum + 1, abs.fuzz, abs.flat,
                                   abs.resolution);
                        }
                    }
                    count++;
                }
        }
        if (count)
            printf("\n");
    }
    free(bits);
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
    int joystick_dev_fd = open(joystick_dev_path, O_RDONLY | O_NONBLOCK);
    getABSRange(joystick_dev_fd);
    close(joystick_dev_fd);
    while (1)
    {
        no_Exclusive_mode_JoyStick();
        Exclusive_mode_JoyStick();
    }
}
