#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <linux/uinput.h>
#include <linux/input.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <time.h>
#include <stdint.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <libgen.h>
#include <semaphore.h>
#include <pthread.h>
#include <stdbool.h>

#define KEY_CUSTOM_UP 0x20
#define KEY_CUSTOM_DOWN 0x30

#define DEBUG 0

#define DOWN 0x1
#define UP 0x0
#define MOVE_FLAG 0x0
#define RELEASE_FLAG 0x2
#define REQURIE_FLAG 0x1
#define WHEEL_REQUIRE 0X3
#define MOUSE_REQUIRE 0X4
// #define AIM_ANGEL_RANGE 25 //角度范围 正负相等  (!=)
#define AIM_LEN_PIXELS 700 //中心距离
#define CENTER_X 1560      //中心点
#define CENTER_Y 720

#define rand_offset() (rand() % 80 - 40) //随机偏移 不需要改成0
#define mini_rand_offset() (rand() % 20 - 10)

static struct uinput_user_dev uinput_dev;
static int uinput_fd;

int creat_user_uinput(void);
int report_key(unsigned int keycode, unsigned int value);
int sin_fast_vals[91] = {
    //0~90度的sin*1000
    0,
    17,
    34,
    52,
    69,
    87,
    104,
    121,
    139,
    156,
    173,
    190,
    207,
    224,
    241,
    258,
    275,
    292,
    309,
    325,
    342,
    358,
    374,
    390,
    406,
    422,
    438,
    453,
    469,
    484,
    499,
    515,
    529,
    544,
    559,
    573,
    587,
    601,
    615,
    629,
    642,
    656,
    669,
    681,
    694,
    707,
    719,
    731,
    743,
    754,
    766,
    777,
    788,
    798,
    809,
    819,
    829,
    838,
    848,
    857,
    866,
    874,
    882,
    891,
    898,
    906,
    913,
    920,
    927,
    933,
    939,
    945,
    951,
    956,
    961,
    965,
    970,
    974,
    978,
    981,
    984,
    987,
    990,
    992,
    994,
    996,
    997,
    998,
    999,
    999,
    1000};
int fast_sin(int angle)
{
    int new_val = (angle % 360 + 360) % 360;
    if (new_val < 90)
    {
        return sin_fast_vals[new_val];
    }
    else if (new_val < 180)
    {
        return sin_fast_vals[180 - new_val];
    }
    else if (new_val < 270)
    {
        return sin_fast_vals[new_val - 180] * -1;
    }
    else
    {
        return sin_fast_vals[360 - new_val] * -1;
    }
}
int fast_cos(int angle)
{
    int new_val = (angle % 360 + 360) % 360;
    if (new_val < 90)
    {
        return sin_fast_vals[90 - new_val];
    }
    else if (new_val < 180)
    {
        return sin_fast_vals[new_val - 90] * -1;
    }
    else if (new_val < 270)
    {
        return sin_fast_vals[270 - new_val] * -1;
    }
    else
    {
        return sin_fast_vals[new_val - 270];
    }
}
char touch_dev_path[80];
char keyboard_dev_path[80];
char mouse_dev_path[80];
int keyboard_dev = 16;
int mouse_dev = 15;
int touch_fd;                          //触屏的设备文件指针
int Exclusive_mode_flag = 0;           //独占模式标识
int no_Exclusive_mode_flag = 1;        //刚开始 进入非独占模式
struct input_event Mouse_queue[16];    //鼠标信号队列
int m_len = 0;                         //队列长度
struct input_event Keyboard_queue[16]; //键盘信号队列
int k_len = 0;                         //键盘队列长度
int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int allocatedID_num = 0;
int mouse_touch_id = -1;  //鼠标映射的ID 唯一 第一次产生移动事件时按下 之后只有移动  切换映射的时候才释放
int mouse_Start_x = 720;  ///开始结束坐标
int mouse_Start_y = 1600; //中途可能有切换 还是会回到这里的
int screen_x = 0;
int screen_y = 0;
int realtive_x, realtive_y; //保存当前移动坐标
int mouse_speedRatio = 1;
int km_map_id[256 + 8];                                                                             //键盘鼠标code 对应分配的ID 按下获取并存入 释放的时候就从这里获取ID释放
                                                                                                    //鼠标编码0x110开始 0~7个
                                                                                                    //将其放在了一起 鼠标加偏移量256
int map_postion[256 + 8][2];                                                                        //映射的XY坐标
int wheel_satuse[4];                                                                                //wasd按键状态                                                                                                                    //默认为0 初始化时和结束时也手动清0
int wheel_postion[9][2] = {{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}}; //8个状态的坐标
int wheel_touch_id = -1;
int cur_x = 0, cur_y = 0;                                                                        //当前位置
int tar_x = 0, tar_y = 0;                                                                        //目标位置
int move_speed = 60;                                                                             //方向移动速度
int frequency = 5000;                                                                            //方向移动频率 关系到相应方向键速度
int release_flag = 0;                                                                            //确保释放操作只执行一次
bool move_event_flag = false;                                                                    //鼠标事件标识
int none_mouse_event_count = 0;                                                                  //无鼠标事件周期数
int roll_touch_id = -1;                                                                          //滚轮id
int aim_angel = 15;                                                                              //倍镜缩放 角度，坐标能算出来
bool roll_event_flag = false;                                                                    //滚动事件标识
int none_roll_event_count = 0;                                                                   //无滚动事件周期数
struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};              //同步 最常用的 直接用
struct input_event SWITCH_ID_EVENT = {.type = EV_ABS, .code = ABS_MT_SLOT, .value = 0xffffffff}; //切换触摸点 修改value再用
struct input_event POS_X_EVENT = {.type = EV_ABS, .code = ABS_MT_POSITION_X};                    //X坐标
struct input_event POS_Y_EVENT = {.type = EV_ABS, .code = ABS_MT_POSITION_Y};                    //Y坐标
struct input_event DEFINE_UID_EVENT = {.type = EV_ABS, .code = ABS_MT_TRACKING_ID};              //声明识别ID 用于消除
struct input_event BTN_DOWN_EVENT = {.type = EV_KEY, .code = BTN_TOUCH, .value = DOWN};          //按下 没有触摸点的时候使用
struct input_event BTN_UP_EVENT = {.type = EV_KEY, .code = BTN_TOUCH, .value = UP};              //释放 触摸点全部释放的时候使用
//type = 0,1,2 id = -1,.... ,x,y      ID为-1 则是按下，获取返回的ID，下次带上才可进行滑动或者释放操作
//x,y为绝对坐标 越界重置也由外部完成
//按下 移动 释放
//滑动 = 按下+移动+释放
//不提供点击功能
//点击 = 按下 + 释放
//超出10点个不响应
//返回触摸点的ID 下次带上
//鼠标的映射 鼠标一开始就占一个 切换后才释放 是申请还是移动 在外边判断
//由于多线程 保证安全加上PV
sem_t touch_dev_controler_sem_control;
bool mouse_touch_allocater = true; //鼠标每次越界重新分配ID 0/1 尝试解决视角问题
int touch_dev_controler(int type, int unclear_id, int x, int y)
{
    sem_wait(&touch_dev_controler_sem_control);
    int id = unclear_id;
    if ((type == MOVE_FLAG) && (id != -1)) //移动:  切换ID,X,Y,同步 编码格式 "0 id x y"
    {
        if (SWITCH_ID_EVENT.value != id)
        {
            SWITCH_ID_EVENT.value = id;
            write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
        }
        POS_X_EVENT.value = x;
        POS_Y_EVENT.value = y;
        write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
        write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
        write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
    }
    else if ((type == RELEASE_FLAG) && (id != -1)) //释放: 切换ID,uid=-1,同步 编码格式 "2 id * *"
    {
        touch_id[id] = 0;  // 释放
        allocatedID_num--; //占用数目-1
        if (SWITCH_ID_EVENT.value != id)
        {
            SWITCH_ID_EVENT.value = id;
            write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
        }
        DEFINE_UID_EVENT.value = 0xffffffff;
        write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
        if (allocatedID_num == 0) //为0 全部释放 btn up
        {
            write(touch_fd, &BTN_UP_EVENT, sizeof(BTN_UP_EVENT));
        }
        write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
    }
    else if (type == MOUSE_REQUIRE || type == WHEEL_REQUIRE || type == REQURIE_FLAG)
    { //按下： 切换ID，uid=自定义，x，y，同步 编码格式 "1 * x y"
        if (type == MOUSE_REQUIRE)
        {
            id = mouse_touch_allocater ? 0 : 1;
            mouse_touch_allocater = !mouse_touch_allocater;
        }
        else if (type == WHEEL_REQUIRE)
            id = 2;
        else
        {
            for (int i = 3; i < 10; i++) // 0 1 保留给鼠标移动和方向控制
            {
                if (touch_id[i] == 0) //找寻一个空的
                {
                    id = i; //分配id
                    break;
                }
            }
        }
        if (id != -1)
        {
            touch_id[id] = 1; //记录此置位已占用
            allocatedID_num++;
            SWITCH_ID_EVENT.value = id;
            DEFINE_UID_EVENT.value = id;
            POS_X_EVENT.value = x;
            POS_Y_EVENT.value = y;
            write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
            write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
            if (allocatedID_num == 1)
            { //为1 则是头一次按下 btn down
                write(touch_fd, &BTN_DOWN_EVENT, sizeof(BTN_DOWN_EVENT));
            }
            write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
            write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
            write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
        }
    }
    if (DEBUG == 1)
    {
        // printf("[%d,%d,%d,%d,%d]\n", type, unclear_id, x, y, id);
        printf("[type=%d\t,ucid=%d\t,x=%d\t,y=%d\t,allocated id=%d]\n", type, unclear_id, x, y, id);
    }

    sem_post(&touch_dev_controler_sem_control);
    return id;
}

void aim_change_focus(int val)
{
    int new_angle = aim_angel + val;
    if ((new_angle > 25) || (new_angle < -15))
    {
        // printf("%d pass\n", new_angle);
        return;
    }
    // printf("%d -> %d \n", aim_angel, new_angle);
    int old_x = CENTER_X - AIM_LEN_PIXELS * fast_cos(aim_angel) / 1000;
    int old_y = CENTER_Y + AIM_LEN_PIXELS * fast_sin(aim_angel) / 1000;
    int new_x = CENTER_X - AIM_LEN_PIXELS * fast_cos(new_angle) / 1000;
    int new_y = CENTER_Y + AIM_LEN_PIXELS * fast_sin(new_angle) / 1000;
    roll_event_flag = true;
    if (roll_touch_id == -1)
    {
        roll_touch_id = touch_dev_controler(REQURIE_FLAG, -1, old_y, old_x);
    }

    // printf("move from [%d,%d] to [%d,%d]\n\n", old_x, old_y, new_x, new_y);
    touch_dev_controler(MOVE_FLAG, roll_touch_id, new_y, new_x);
    aim_angel = new_angle;
}

void manager_thread()
{
    while (1)
    {
        if (Exclusive_mode_flag)
        {

            if (release_flag > 0 && tar_x == wheel_postion[4][0] && tar_y == wheel_postion[4][1]) //目标是中点 则直接释放
            {
                cur_x = tar_x;
                cur_y = tar_y;
                touch_dev_controler(RELEASE_FLAG, wheel_touch_id, 0, 0); //释放
                wheel_touch_id = -1;
                release_flag--; //确保在不按下按键时 执行
            }
            else
            {
                int div_x = tar_x - cur_x;
                int div_y = tar_y - cur_y;
                if (div_x)
                {
                    if (abs(div_x) > move_speed)
                        cur_x += div_x > 0 ? 1 * move_speed : -1 * move_speed;
                    else
                        cur_x = tar_x;
                }
                if (div_y)
                {
                    if (abs(div_y) > move_speed)
                        cur_y += div_y > 0 ? 1 * move_speed : -1 * move_speed;
                    else
                        cur_y = tar_y;
                }
                if (div_x || div_y)
                    touch_dev_controler(MOVE_FLAG, wheel_touch_id, cur_x + mini_rand_offset(), cur_y + mini_rand_offset()); //正常移动
            }
            //追加部分 用于鼠标回位
            if (move_event_flag)
            {
                none_mouse_event_count = 0;
                move_event_flag = false;
            }
            else
            {
                if (none_mouse_event_count == 50)
                {
                    touch_dev_controler(RELEASE_FLAG, mouse_touch_id, 0, 0);
                    mouse_touch_id = -1;
                }
                else
                {
                    none_mouse_event_count++;
                }
            }
            //追加部分 用于连续瞄准缩放
            if (roll_event_flag)
            {
                none_roll_event_count = 0;
                roll_event_flag = false;
            }
            else
            {
                if (none_roll_event_count == 50)
                {
                    touch_dev_controler(RELEASE_FLAG, roll_touch_id, 0, 0);
                    roll_touch_id = -1;
                }
                else
                {
                    none_roll_event_count++;
                }
            }
        }

        usleep(frequency);
    }
}
void change_wheel_satuse(int keyCode, int updown)
{
    int x_Asix = 1 - wheel_satuse[1] + wheel_satuse[3];
    int y_Asix = 1 - wheel_satuse[2] + wheel_satuse[0];
    int last_map_value = x_Asix * 3 + y_Asix;
    int index = -1;
    switch (keyCode)
    {
    case KEY_W:
        wheel_satuse[0] = updown;
        break;
    case KEY_A:
        wheel_satuse[1] = updown;
        break;
    case KEY_S:
        wheel_satuse[2] = updown;
        break;
    case KEY_D:
        wheel_satuse[3] = updown;
        break;
    default:
        break;
    }
    x_Asix = 1 - wheel_satuse[1] + wheel_satuse[3];
    y_Asix = 1 - wheel_satuse[2] + wheel_satuse[0];
    int map_value = x_Asix * 3 + y_Asix;
    if (last_map_value == 4 && map_value != 4) //按下 移动
    {
        tar_x = wheel_postion[4][0];
        tar_y = wheel_postion[4][1];
        cur_x = tar_x;
        cur_y = tar_y;                                                                                         //设置起始位置和目标位置为中点
        wheel_touch_id = touch_dev_controler(WHEEL_REQUIRE, -1, cur_x + rand_offset(), cur_y + rand_offset()); //按下中点
        tar_x = wheel_postion[map_value][0] + rand_offset();
        tar_y = wheel_postion[map_value][1] + rand_offset(); //设置移动目标
    }
    else
    {
        if (map_value != 4) //正常移动
        {
            tar_x = wheel_postion[map_value][0] + rand_offset();
            tar_y = wheel_postion[map_value][1] + rand_offset();
        }
        else //移动目标为中点 释放
        {
            release_flag++; //确保只释放一次
            tar_x = wheel_postion[4][0];
            tar_y = wheel_postion[4][1]; //管理器检测目标为中点 直接释放
        }
    }
}

struct input_event single_queue[16]; //整合设备信号队列
int s_len = 0;                       //整合队列长度
void handelEventQueue()              //处理所有事件
{
    int x = 0;
    int y = 0;
    for (int i = 0; i < s_len; i++) //main loop
    {
        if (single_queue[i].code == KEY_GRAVE && single_queue[i].value == UP) //独占和非独占都关注 ` 用于切换状态  `键不响应键盘映射
        {
            int tmp = Exclusive_mode_flag;
            Exclusive_mode_flag = no_Exclusive_mode_flag;
            no_Exclusive_mode_flag = tmp;
            break;
        }
        if (Exclusive_mode_flag)
        {
            if (single_queue[i].type == EV_REL)
            {
                if (single_queue[i].code == REL_X)
                    x = single_queue[i].value;
                else if (single_queue[i].code == REL_Y)
                    y = single_queue[i].value;
                else if (single_queue[i].code == REL_WHEEL) //滚轮事件
                {
                    aim_change_focus(single_queue[i].value * 5);
                }
            }
            else if (single_queue[i].type == EV_KEY)
            {
                int keyCode = single_queue[i].code > 256 ? 256 + single_queue[i].code - BTN_MOUSE : single_queue[i].code;
                int updown = single_queue[i].value;
                if (keyCode == KEY_W || keyCode == KEY_A || keyCode == KEY_S || keyCode == KEY_D) //方向键 额外处理
                    change_wheel_satuse(keyCode, updown);
                else if (map_postion[keyCode][0] && map_postion[keyCode][1])
                { //映射坐标不为0 设定映射
                    if (updown == DOWN)
                        km_map_id[keyCode] = touch_dev_controler(REQURIE_FLAG, -1, map_postion[keyCode][0] + rand_offset(), map_postion[keyCode][1] + rand_offset()); //按下
                    else
                        touch_dev_controler(RELEASE_FLAG, km_map_id[keyCode], 0, 0); //释放
                }
            }
        }
    }
    if (Exclusive_mode_flag == 1 && (x != 0 || y != 0))
    { //有鼠标事件
        move_event_flag = true;
        realtive_x -= y * mouse_speedRatio;
        realtive_y += x * mouse_speedRatio;
        if (mouse_touch_id == -1 || realtive_x < 32 || realtive_x > screen_x || realtive_y < 32 || realtive_y > screen_y)
        {
            int rand_X = rand_offset();
            int rand_Y = rand_offset();
            touch_dev_controler(RELEASE_FLAG, mouse_touch_id, 0, 0);                                                 //松开
            mouse_touch_id = touch_dev_controler(MOUSE_REQUIRE, -1, mouse_Start_x + rand_X, mouse_Start_y + rand_Y); //再按下
            realtive_x = mouse_Start_x + rand_X - y * mouse_speedRatio;
            realtive_y = mouse_Start_y + rand_Y + x * mouse_speedRatio; //相对X,Y
        }
        touch_dev_controler(MOVE_FLAG, mouse_touch_id, realtive_x, realtive_y); //移动
    }
    s_len = 0;
}

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
    pthread_t manager_thread_thread;
    pthread_create(&manager_thread_thread, NULL, (void *)&manager_thread, NULL);
    while (1)
    {
        memset(message, '\0', 16);
        recvfrom(socket_descriptor, message, sizeof(message), 0, (struct sockaddr *)&sin, &sin_len);
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
                mouse_x -= 10000;
            if (mouse_y > 5000)
                mouse_y -= 10000;
            repreport_mouse_move(mouse_x, mouse_y);
            break;
        }
        case 1:
        {
            report_key(code, 1);
            break;
        }
        case 2:
        {
            report_key(code, 0);
            break;
        }
        case 3:
        {
            report_key(code - 5000, 3);
        }

        default:
            break;
        }
    }
    close(socket_descriptor);
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
    ioctl(uinput_fd, UI_SET_RELBIT, REL_WHEEL);

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

    if (keycode == KEY_GRAVE) //独占和非独占都关注 ` 用于切换状态  `键不响应键盘映射
    {
        if (value == UP) //不响应 `
        {
            for (int i = 0; i < 4; i++) //初始化
                wheel_satuse[i] = 0;    //清除方向盘状态
            cur_x = wheel_postion[4][0];
            cur_y = wheel_postion[4][1];
            tar_x = cur_x;
            tar_y = cur_y; //管理器位置重置
            for (int i = 0; i < 10; i++)
                if (touch_id[i] != 0)
                    touch_dev_controler(RELEASE_FLAG, i, 0, 0); //释放所有按键
            realtive_x = mouse_Start_x;
            realtive_y = mouse_Start_y; //相对X,Y
            wheel_touch_id = -1;
            mouse_touch_id = -1;
            SWITCH_ID_EVENT.value = 0xffffffff;
            allocatedID_num = 0;

            int tmp = Exclusive_mode_flag;
            Exclusive_mode_flag = no_Exclusive_mode_flag;
            no_Exclusive_mode_flag = tmp;
            return 0;
        }
        else
        {
            return 0;
        }
    }

    if (value == 3) // 3 滚轮 keycode正负代表前后
    {
        // printf("[value = 3,keycode = %d]\n", keycode);
        struct input_event EV_KEY_EVENT = {.type = EV_REL, .code = REL_WHEEL, .value = keycode};
        struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
        if (Exclusive_mode_flag)
        {
            single_queue[0] = EV_KEY_EVENT;
            single_queue[1] = SYNC_EVENT;
            s_len = 2;
            handelEventQueue();
        }
        else
        {
            write(uinput_fd, &EV_KEY_EVENT, sizeof(struct input_event));
            write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
        }
    }
    else
    {
        struct input_event EV_KEY_EVENT = {.type = EV_KEY, .code = keycode, .value = value};
        struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
        if (Exclusive_mode_flag)
        {
            single_queue[0] = EV_KEY_EVENT;
            single_queue[1] = SYNC_EVENT;
            s_len = 2;
            handelEventQueue();
        }
        else
        {
            write(uinput_fd, &EV_KEY_EVENT, sizeof(struct input_event));
            write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
        }
    }
    return 0;
}

int repreport_mouse_move(unsigned int x, unsigned int y)
{
    struct input_event REL_X_EVENT = {.type = EV_REL, .code = REL_X, .value = x};
    struct input_event REL_Y_EVENT = {.type = EV_REL, .code = REL_Y, .value = y};
    struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};
    if (Exclusive_mode_flag)
    {
        single_queue[0] = REL_X_EVENT;
        single_queue[1] = REL_Y_EVENT;
        single_queue[2] = SYNC_EVENT;
        s_len = 3;
        handelEventQueue();
    }
    else
    {
        write(uinput_fd, &REL_X_EVENT, sizeof(struct input_event));
        write(uinput_fd, &REL_Y_EVENT, sizeof(struct input_event));
        write(uinput_fd, &SYNC_EVENT, sizeof(struct input_event));
    }
    return 0;
}

int main(int argc, char *argv[]) //触屏设备号 键盘设备号 鼠标设备号 mapper映射文件路径
                                 //首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{
    srand((unsigned)time(NULL)); //点击坐标+随机数
    int touch_dev_num = atoi(argv[1]);
    sprintf(touch_dev_path, "/dev/input/event%d", touch_dev_num);
    printf("Touch_dev_path:%s\n", touch_dev_path);
    if (sem_init(&touch_dev_controler_sem_control, 0, 1) != 0)
    {
        perror("Fail to touch_dev_controler_sem_control init");
        exit(-1);
    }
    char buf[1024 * 8];      //配置文件大小最大8KB
    chdir(dirname(argv[0])); //设置当前目录为应用程序所在的目录
    printf("Reading config from %s\n", argv[2]);
    FILE *fp = fopen(argv[2], "r");
    if (fp == NULL)
    {
        fprintf(stderr, "Can't read map file from %s, %s\n", argv[2], strerror(errno));
        exit(-2);
    }
    fread(buf, 1024 * 8, 1, fp);
    fclose(fp);
    int linecount = 0;
    char lines[68][32];
    char *token = strtok(buf, "\n");
    while (token != NULL)
    {
        strcpy(lines[linecount++], token);
        token = strtok(NULL, "\n");
    }
    int config[68][3];
    for (int i = 0; i < linecount; i++)
    {
        char *rowData = strtok(lines[i], " ");
        config[i][0] = atoi(rowData);
        config[i][1] = atoi(strtok(NULL, " "));
        config[i][2] = atoi(strtok(NULL, " "));
    }
    mouse_Start_x = config[0][0];
    mouse_Start_y = config[0][1];
    screen_x = mouse_Start_x * 2 - 32;
    screen_y = (mouse_Start_y - 200) * 2 - 32;
    mouse_speedRatio = config[0][2];
    for (int i = 0; i < 9; i++)
    {
        wheel_postion[i][0] = config[i + 1][1];
        wheel_postion[i][1] = config[i + 1][2];
    }
    for (int i = 9; i < linecount; i++)
    {
        map_postion[config[i][0]][0] = config[i][1];
        map_postion[config[i][0]][1] = config[i][2];
    }

    int ret = 0;
    ret = creat_user_uinput();
    if (ret < 0)
    {
        printf("%s:%d\n", __func__, __LINE__);
        return -1; //error process.
    }
    touch_fd = open(touch_dev_path, O_RDWR);
    reveive_from_UDP(8848);
    close(uinput_fd);
    close(touch_fd);
}