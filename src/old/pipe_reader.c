#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <stdio.h>
#include <linux/input.h>
#include "key_define.h"

// struct input_event
// {
//     struct timeval time;
//     __u16 type;
//     __u16 code;
//     __s32 value;
// };

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
    //就到这里吧  只用来处理鼠标就行了 毕竟鼠标延迟最重要
    //键盘会有Segmentation fault
    //而且我现在有没有HUB 所以键盘就做不做了   仍然用PC来输入
    //这个进程也只用于发送UDP  所以总共启动3个进程
    return;
}

void handelEvent(char *event, int type, int code, int value) //是按照插入顺序分配的  先插鼠标 再插键盘
{
    if (!strcmp(event, mouse_dev))
    {
        m_q[m_len].type = type;
        m_q[m_len].code = code;
        m_q[m_len].value = value;
        m_len++;
        if (type == 0 && code == 0 && value == 0)
            handel_m_q();
    }
    else if (!strcmp(event, keyboard_dev))
    {
        k_q[k_len].type = type;
        k_q[k_len].code = code;
        k_q[k_len].value = value;
        k_len++;
        if (type == 0 && code == 0 && value == 0)
            handel_k_q();
    }
    else
        return;
}

int main()
{
    const char *fifo_name = "/data/data/com.termux/files/usr/tmp/namedFifo";
    int pipe_fd = -1;
    int res = 0;
    int open_mode = O_RDONLY;
    char buffer[PIPE_BUF + 1];
    printf("进程[%d]只读\n", getpid());
    printf("等待写入进程\n");
    pipe_fd = open(fifo_name, open_mode);
    printf("写入进程已启动\n");
    //==================管道进程初始化=====================

    //==================控制进程初始化=====================
    while (1)
    {
        memset(buffer, '\0', sizeof(buffer));
        res = read(pipe_fd, buffer, PIPE_BUF);
        if (res != 0)
        {
            // printf("%s\n", buffer); // like : /dev/input/eventX,123,456,789
            char *token = strtok(buffer, ",");
            char *event = (token);               // /dev/input/eventX
            int type = atoi(strtok(NULL, ","));  // type
            int code = atoi(strtok(NULL, ","));  // code
            int value = atoi(strtok(NULL, ",")); // value
            // printf("%s\t%d\t%d\t%d\n", event, type, code, value);
            handelEvent(event, type, code, value);
        }
        else
            break;
    }
    close(pipe_fd);
    exit(EXIT_SUCCESS);
}
