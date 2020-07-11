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

#include "key_define.h"

int Exclusive_mode_flag = 0;
int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式
struct input_event m_q[16];
int m_len = 0;

struct input_event k_q[16];
int k_len = 0;

void handel_m_q() //处理鼠标动作
{
    if (m_q[0].type == 2) //移动
    {
        int x = 0;
        int y = 0;
        if (m_len == 3)
        { //X和Y 顺序是固定的 先X 后y
            x = m_q[0].value;
            y = m_q[1].value;
        }
        else
        { //单个 x或y
            if (m_q[0].code == 0)
                x = m_q[0].value;
            else
                y = m_q[0].value;
        }
        printf("[%d,%d]\n", x, y);
    }
    else if (m_q[0].type == EV_MSC) //点击
    {
        int LR;
        int DU;
        if (m_q[1].code == BTN_MOUSE) //左键
            LR = 0;
        else if (m_q[1].code == BTN_RIGHT) //右键
            LR = 1;
        if (m_q[1].value == DOWN)
            DU = 0;
        else if (m_q[1].value == UP)
            DU = 1;
        switch (LR * 10 + DU)
        {
        case 0: //左键按下
            printf("L DOWN\n");
            break;
        case 1: //左键释放
            printf("L UP\n");
            break;
        case 10: //右键按下
            printf("R DOWN\n");
            break;
        case 11: //右键释放
            printf("R UP\n");
            break;
        default:
            break;
        }
    }
    m_len = 0;
    return;
}
void handel_k_q() //处理键盘动作
{

    int keyCode = k_q[k_len - 2].code;
    int updown = k_q[k_len - 2].value;
    if ((keyCode == KEY_GRAVE) && (updown == UP)) //独占和非独占都关注 ` 用于切换状态
    {
        printf("切换\n");
        int tmp = Exclusive_mode_flag;
        Exclusive_mode_flag = no_Exclusive_mode_flag;
        no_Exclusive_mode_flag = tmp;
    }
    if (Exclusive_mode_flag == 1)
    { //独占模式下 才会处理其他信号 非独占不处理
        printf("{ code = %d , UD = %d }\n", keyCode, updown);
    }

    k_len = 0;
    return;
}

void handelEvent(int flag, struct input_event receive_event) //是按照插入顺序分配的  先插鼠标 再插键盘
{
    if (flag == mouse_dev)
    {
        m_q[m_len] = receive_event;
        m_len++;
        if (receive_event.type == 0 && receive_event.code == 0 && receive_event.value == 0)
            handel_m_q();
    }
    else if (flag == keyboard_dev)
    {
        k_q[k_len] = receive_event;
        k_len++;
        if (receive_event.type == 0 && receive_event.code == 0 && receive_event.value == 0)
            handel_k_q();
    }
    else
        return;
}

int Exclusive_mode()
{
    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open("/dev/input/event15", O_RDONLY | O_NONBLOCK);
    if (keyboard_fd == -1)
    {
        printf("Failed to open keyboard.\n");
        exit(1);
    }
    rcode = ioctl(keyboard_fd, EVIOCGNAME(sizeof(keyboard_name)), keyboard_name);
    printf("Reading From : %s \n", keyboard_name);
    printf("Getting exclusive access: ");
    rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
    printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
    struct input_event keyboard_event;

    char mouse_name[256] = "Unknown";
    int mouse_fd = open("/dev/input/event16", O_RDONLY | O_NONBLOCK);
    if (mouse_fd == -1)
    {
        printf("Failed to open mouse.\n");
        exit(1);
    }
    rcode = ioctl(mouse_fd, EVIOCGNAME(sizeof(mouse_name)), mouse_name);
    printf("Reading From : %s \n", mouse_name);
    printf("Getting exclusive access: ");
    rcode = ioctl(mouse_fd, EVIOCGRAB, 1);
    printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
    struct input_event mouse_event;
    int end = time(NULL) + 10;
    while (Exclusive_mode_flag == 1)
    {
        if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
        {
            // printf("keyboard event: type %d code %d value %d                \n", keyboard_event.type, keyboard_event.code, keyboard_event.value);
            handelEvent(keyboard_dev, keyboard_event);
        }

        if (read(mouse_fd, &mouse_event, sizeof(mouse_event)) != -1)
        {
            // printf("mouse event: type %d code %d value %d                 \n", mouse_event.type, mouse_event.code, mouse_event.value);
            handelEvent(mouse_dev, mouse_event);
        }
    }
    printf("Exiting.\n");
    rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
    close(keyboard_fd);
    rcode = ioctl(mouse_fd, EVIOCGRAB, 1);
    close(mouse_fd);
    return 0;
}

int no_Exclusive_mode()
{
    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open("/dev/input/event15", O_RDONLY | O_NONBLOCK);
    if (keyboard_fd == -1)
    {
        printf("Failed to open keyboard.\n");
        exit(1);
    }
    rcode = ioctl(keyboard_fd, EVIOCGNAME(sizeof(keyboard_name)), keyboard_name);
    printf("Reading From : %s \n", keyboard_name);
    // printf("Getting exclusive access: ");
    // rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
    // printf("%s\n", (rcode == 0) ? "SUCCESS" : "FAILURE");
    struct input_event keyboard_event;

    while (no_Exclusive_mode_flag == 1)
    {
        if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
        {
            // printf("keyboard event: type %d code %d value %d                \n", keyboard_event.type, keyboard_event.code, keyboard_event.value);
            handelEvent(keyboard_dev, keyboard_event);
        }
    }
    printf("Exiting.\n");
    // rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
    close(keyboard_fd);
    return 0;
}
int main(int argc, char *argv[]) //首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{
    while (1)
    {
        no_Exclusive_mode();
        Exclusive_mode(); //记得先插鼠标 再插键盘
    }
}
