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

#define DOWN 0x1
#define UP 0x0
#define MOVE_FLAG 0x0
#define RELEASE_FLAG 0x2
#define REQURIE_FLAG 0x1

char touch_dev_path[80];
char keyboard_dev_path[80];
char mouse_dev_path[80];

int keyboard_dev = 16;
int mouse_dev = 15;

int touch_fd; //触屏的设备文件指针

int Exclusive_mode_flag = 0;    //独占模式标识
int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式

struct input_event Mouse_queue[16]; //鼠标信号队列
int m_len = 0;                      //队列长度

struct input_event Keyboard_queue[16]; //键盘信号队列
int k_len = 0;                         //键盘队列长度

int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int postion[10][2];
int allocatedID_num = 0;

struct input_event SYNC_EVENT = {0, EV_SYN, SYN_REPORT, 0};               //同步 最常用的 直接用
struct input_event SWITCH_ID_EVENT = {0, EV_ABS, ABS_MT_SLOT, 0};         //切换触摸点 修改value再用
struct input_event POS_X_EVENT = {0, EV_ABS, ABS_MT_POSITION_X, 0};       //X坐标
struct input_event POS_Y_EVENT = {0, EV_ABS, ABS_MT_POSITION_Y, 0};       //Y坐标
struct input_event DEFINE_UID_EVENT = {0, EV_ABS, ABS_MT_TRACKING_ID, 0}; //声明识别ID 用于消除
struct input_event BTN_DOWN_EVENT = {0, EV_KEY, BTN_TOUCH, 1};            //按下 没有触摸点的时候使用
struct input_event BTN_UP_EVENT = {0, EV_KEY, BTN_TOUCH, 0};              //释放 触摸点全部释放的时候使用
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
sem_t sem_control;
int main_controler(int type, int unclear_id, int x, int y)
{
    sem_wait(&sem_control);
    int id = unclear_id;
    if (type == MOVE_FLAG) //移动:  切换ID,X,Y,同步 编码格式 "0 id x y"
    {
        SWITCH_ID_EVENT.value = id;
        POS_X_EVENT.value = x;
        POS_Y_EVENT.value = y;
        write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
        write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
        write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
        write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
    }
    else if (type == RELEASE_FLAG) //释放: 切换ID,uid=-1,同步 编码格式 "2 id 0 0"
    {
        if (id == -1)
        {
            sem_post(&sem_control);
            return -1;
        }                  //没申请成功的释放请求
        touch_id[id] = 0;  // 释放
        allocatedID_num--; //占用数目-1
        SWITCH_ID_EVENT.value = id;
        DEFINE_UID_EVENT.value = 0xffffffff;
        write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
        write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
        if (allocatedID_num == 0) //为0 全部释放 btn up
            write(touch_fd, &BTN_UP_EVENT, sizeof(BTN_UP_EVENT));
        write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
    }
    else if (type == REQURIE_FLAG)
    {                 //type == pressTouch  按下： 切换ID，uid=自定义，x，y，同步 编码格式 "1 -1 x y"
        if (id == -1) //申请触摸 是一个新的触摸点 或者申请没有成功 理论上是继续拒绝
        {
            for (int i = 0; i < 10; i++)
            {
                if (touch_id[i] == 0) //找寻一个空的
                {
                    id = i;          //分配id
                    touch_id[i] = 1; //记录此置位已占用
                    postion[i][0] = x;
                    postion[i][1] = y; //更新位置
                    allocatedID_num++; //已分配计数+1
                    break;
                }
            }
        }
        if (id == -1)
        { //分配失败 下次再说
            sem_post(&sem_control);
            return -1;
        }
        SWITCH_ID_EVENT.value = id;
        DEFINE_UID_EVENT.value = 0xe2 + SWITCH_ID_EVENT.value;
        POS_X_EVENT.value = x;
        POS_Y_EVENT.value = y;
        write(touch_fd, &SWITCH_ID_EVENT, sizeof(SWITCH_ID_EVENT));
        write(touch_fd, &DEFINE_UID_EVENT, sizeof(DEFINE_UID_EVENT));
        if (allocatedID_num == 1) //为1 则是头一次按下 btn down
            write(touch_fd, &BTN_DOWN_EVENT, sizeof(BTN_DOWN_EVENT));
        write(touch_fd, &POS_X_EVENT, sizeof(POS_X_EVENT));
        write(touch_fd, &POS_Y_EVENT, sizeof(POS_Y_EVENT));
        write(touch_fd, &SYNC_EVENT, sizeof(SYNC_EVENT));
    }
    sem_post(&sem_control);
    return id;
}

int mouse_touch_id = -1;    //鼠标映射的ID 唯一 第一次产生移动事件时按下 之后只有移动  切换映射的时候才释放
int mouse_Start_x = 720;    ///开始结束坐标 只读
int mouse_Start_y = 1600;   //中途可能有切换 还是会回到这里的
int realtive_x, realtive_y; //保存当前移动坐标
int mouse_speedRatio = 1;
int km_map_id[256 + 8];      //键盘鼠标code 对应分配的ID 按下获取并存入 释放的时候就从这里获取ID释放
                             //鼠标编码0x110开始 0~7个
                             //将其放在了一起 鼠标加偏移量256
int map_postion[256 + 8][2]; //映射的XY坐标

void handel_Mouse_queue() //处理鼠标动作
{

    if (Mouse_queue[0].type == 2) //移动
    {
        int x = 0;
        int y = 0;
        if (m_len == 3)
        { //X和Y 顺序是固定的 先X 后y
            x = Mouse_queue[0].value;
            y = Mouse_queue[1].value;
        }
        else
        { //单个 x或y
            if (Mouse_queue[0].code == 0)
                x = Mouse_queue[0].value;
            else
                y = Mouse_queue[0].value;
        }

        if (mouse_touch_id == -1)
        {
            mouse_touch_id = main_controler(REQURIE_FLAG, mouse_touch_id, mouse_Start_x, mouse_Start_y); //按下 获取ID 应该为0
            realtive_x = mouse_Start_x;
            realtive_y = mouse_Start_y; //相对X,Y
            return;
        }
        realtive_x -= y * mouse_speedRatio;
        realtive_y += x * mouse_speedRatio;
        if (realtive_x < 100 || realtive_x > 1400 || realtive_y < 100 || realtive_y > 3000)
        {
            main_controler(RELEASE_FLAG, mouse_touch_id, 0, 0);
            mouse_touch_id = -1;                                                                         //松开
            mouse_touch_id = main_controler(REQURIE_FLAG, mouse_touch_id, mouse_Start_x, mouse_Start_y); //再按下
            realtive_x = mouse_Start_x;
            realtive_y = mouse_Start_y; //相对X,Y
        }
        main_controler(MOVE_FLAG, mouse_touch_id, realtive_x, realtive_y); //移动
        // printf("[%d,%d]\n", realtive_x, realtive_y);
    }
    else if (Mouse_queue[0].type == EV_MSC) //点击事件
    {
        int mouse_code = 256 + Mouse_queue[1].code - BTN_MOUSE; //0x110为左键 -0x110获得鼠标按键偏移
        if (Mouse_queue[1].value == DOWN)                       //按下
            km_map_id[mouse_code] = main_controler(REQURIE_FLAG, -1, map_postion[mouse_code][0], map_postion[mouse_code][1]);
        else //释放
            main_controler(RELEASE_FLAG, km_map_id[mouse_code], 0, 0);
    }
    m_len = 0;
    return;
}

int wheel_satuse[4];                                                                                //wasd按键状态                                                                                                                    //默认为0 初始化时和结束时也手动清0
int wheel_postion[9][2] = {{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}}; //8个状态的坐标
int wheel_touch_id = -1;
int cur_x = 0, cur_y = 0; //当前位置
int tar_x = 0, tar_y = 0; //目标位置
int move_speed = 5;       //方向移动速度
int frequency = 500;      //方向移动频率 关系到相应方向键速度
int release_flag = 0;     //确保释放操作只执行一次
void wheel_manager()
{
    while (Exclusive_mode_flag) //与独占模式共存亡
    {
        if (release_flag > 0 && tar_x == wheel_postion[4][0] && tar_y == wheel_postion[4][1]) //目标是中点 则直接释放
        {
            cur_x = tar_x;
            cur_y = tar_y;
            main_controler(RELEASE_FLAG, wheel_touch_id, 0, 0); //释放
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
                main_controler(MOVE_FLAG, wheel_touch_id, cur_x, cur_y); //正常移动
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
        cur_y = tar_y;                                                                               //设置起始位置和目标位置为中点
        wheel_touch_id = main_controler(REQURIE_FLAG, -1, wheel_postion[4][0], wheel_postion[4][1]); //按下中点
        tar_x = wheel_postion[map_value][0];
        tar_y = wheel_postion[map_value][1]; //设置移动目标
    }
    else
    {
        if (map_value != 4) //正常移动
        {
            tar_x = wheel_postion[map_value][0];
            tar_y = wheel_postion[map_value][1];
        }
        else //移动目标为中点 释放
        {
            tar_x = wheel_postion[4][0];
            tar_y = wheel_postion[4][1]; //管理器检测目标为中点 直接释放
            release_flag++;              //确保只释放一次
        }
    }
}

void handel_Keyboard_queue() //处理键盘动作
{
    int keyCode = Keyboard_queue[k_len - 2].code;
    int updown = Keyboard_queue[k_len - 2].value;
    if (keyCode == KEY_GRAVE && updown == UP) //独占和非独占都关注 ` 用于切换状态  `键不响应键盘映射
    {
        int tmp = Exclusive_mode_flag;
        Exclusive_mode_flag = no_Exclusive_mode_flag;
        no_Exclusive_mode_flag = tmp;
    }
    else if (Exclusive_mode_flag == 1)
    { //独占模式下 才会处理其他信号 非独占不处理
        // printf("{ code = %d , UD = %d }\n", keyCode, updown);
        if (keyCode == KEY_W || keyCode == KEY_A || keyCode == KEY_S || keyCode == KEY_D) //方向键 额外处理
            change_wheel_satuse(keyCode, updown);
        else if (map_postion[keyCode][0] && map_postion[keyCode][1])
        { //映射坐标不为0 设定映射
            if (updown == DOWN)
                km_map_id[keyCode] = main_controler(REQURIE_FLAG, -1, map_postion[keyCode][0], map_postion[keyCode][1]); //按下
            else
                main_controler(RELEASE_FLAG, km_map_id[keyCode], 0, 0); //释放
        }
    }
    k_len = 0; //队列清空
    return;
}

int Exclusive_mode()
{
    touch_fd = open(touch_dev_path, O_RDWR); //触摸设备号
    for (int i = 0; i < 4; i++)
        wheel_satuse[i] = 0; //清除方向盘状态
    if (touch_fd < 0)
    {
        fprintf(stderr, "could not open touchScreen\n");
        int tmp = Exclusive_mode_flag;
        Exclusive_mode_flag = no_Exclusive_mode_flag;
        no_Exclusive_mode_flag = tmp; //切换回非独占
        return 1;
    }

    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open(keyboard_dev_path, O_RDONLY | O_NONBLOCK);
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
    int mouse_fd = open(mouse_dev_path, O_RDONLY | O_NONBLOCK);
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
    cur_x = wheel_postion[4][0];
    cur_y = wheel_postion[4][1];
    tar_x = cur_x;
    tar_y = cur_y; //管理器位置重置
    pthread_t manager_thread;
    pthread_create(&manager_thread, NULL, (void *)&wheel_manager, NULL);
    while (Exclusive_mode_flag == 1)
    {
        if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
        {
            Keyboard_queue[k_len] = keyboard_event;
            k_len++;
            if (keyboard_event.type == 0 && keyboard_event.code == 0 && keyboard_event.value == 0)
                handel_Keyboard_queue();
        }
        if (read(mouse_fd, &mouse_event, sizeof(mouse_event)) != -1)
        {
            Mouse_queue[m_len] = mouse_event;
            m_len++;
            if (mouse_event.type == 0 && mouse_event.code == 0 && mouse_event.value == 0)
                handel_Mouse_queue(); //同步信号 转处理
        }
    }
    printf("Exiting.\n");
    pthread_join(manager_thread, NULL);
    rcode = ioctl(keyboard_fd, EVIOCGRAB, 1);
    close(keyboard_fd);
    rcode = ioctl(mouse_fd, EVIOCGRAB, 1);
    close(mouse_fd); //解除独占状态
    for (int i = 0; i < 4; i++)
        wheel_satuse[i] = 0; //清除方向盘状态
    for (int i = 0; i < 10; i++)
        if (touch_id[i] != 0)
            main_controler(RELEASE_FLAG, i, 0, 0); //释放所有按键
    mouse_touch_id = -1;

    close(touch_fd);
    return 0;
}

int no_Exclusive_mode()
{

    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open(keyboard_dev_path, O_RDONLY | O_NONBLOCK);
    if (keyboard_fd == -1)
    {
        printf("Failed to open keyboard.\n");
        exit(1);
    }
    rcode = ioctl(keyboard_fd, EVIOCGNAME(sizeof(keyboard_name)), keyboard_name);
    printf("Reading From : %s \n", keyboard_name);
    struct input_event keyboard_event;
    while (no_Exclusive_mode_flag == 1)
        if (read(keyboard_fd, &keyboard_event, sizeof(keyboard_event)) != -1)
        {
            Keyboard_queue[k_len] = keyboard_event;
            k_len++;
            if (keyboard_event.type == 0 && keyboard_event.code == 0 && keyboard_event.value == 0)
                handel_Keyboard_queue();
        }
    printf("Exiting.\n");
    close(keyboard_fd);
    return 0;
}

int main(int argc, char *argv[]) //触屏设备号 键盘设备号 鼠标设备号 mapper映射文件路径
                                 //首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{
    int touch_dev_num = atoi(argv[1]);
    int mouse_dev_num = atoi(argv[2]);
    int keyboard_dev_num = atoi(argv[3]);
    mouse_dev = mouse_dev_num;
    keyboard_dev = keyboard_dev_num;
    sprintf(touch_dev_path, "/dev/input/event%d", touch_dev_num);
    sprintf(mouse_dev_path, "/dev/input/event%d", mouse_dev_num);
    sprintf(keyboard_dev_path, "/dev/input/event%d", keyboard_dev_num);
    printf("Touch_dev_path:%s\n", touch_dev_path);
    printf("Mouse_dev_path:%s\n", mouse_dev_path);
    printf("Keyboard_dev_path:%s\n", keyboard_dev_path);
    if (sem_init(&sem_control, 0, 1) != 0)
    {
        perror("Fail to sem_sem_control init");
        exit(-1);
    }
    char buf[1024 * 8];      //配置文件大小最大8KB
    chdir(dirname(argv[0])); //设置当前目录为应用程序所在的目录
    printf("Reading config from %s\n", argv[4]);
    FILE *fp = fopen(argv[4], "r");
    if (fp == NULL)
    {
        fprintf(stderr, "Can't read map file from %s, %s\n", argv[4], strerror(errno));
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

    while (1)
    {
        no_Exclusive_mode();
        Exclusive_mode(); //记得先插鼠标 再插键盘
    }
}
