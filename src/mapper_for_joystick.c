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
#define WHEEL_REQUIRE 0X3
#define MOUSE_REQUIRE 0X4

char touch_dev_path[80];
char joystick_dev_path[80];
int joystick_dev = 15;
int touch_fd;                   //触屏的设备文件指针
int Exclusive_mode_flag = 0;    //独占模式标识
int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式
int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int allocatedID_num = 0;
struct input_event SYNC_EVENT = {.type = EV_SYN, .code = SYN_REPORT, .value = 0x0};          //同步 最常用的 直接用
struct input_event SWITCH_ID_EVENT = {.type = EV_ABS, .code = ABS_MT_SLOT, .value = 0xffff}; //切换触摸点 修改value再用
struct input_event POS_X_EVENT = {.type = EV_ABS, .code = ABS_MT_POSITION_X};                //X坐标
struct input_event POS_Y_EVENT = {.type = EV_ABS, .code = ABS_MT_POSITION_Y};                //Y坐标
struct input_event DEFINE_UID_EVENT = {.type = EV_ABS, .code = ABS_MT_TRACKING_ID};          //声明识别ID 用于消除
struct input_event BTN_DOWN_EVENT = {.type = EV_KEY, .code = BTN_TOUCH, .value = DOWN};      //按下 没有触摸点的时候使用
struct input_event BTN_UP_EVENT = {.type = EV_KEY, .code = BTN_TOUCH, .value = UP};          //释放 触摸点全部释放的时候使用
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
    else if (type == REQURIE_FLAG)
    {                                //按下： 切换ID，uid=自定义，x，y，同步 编码格式 "1 * x y"
        for (int i = 2; i < 10; i++) // 0 1 保留给鼠标移动和方向控制
        {
            if (touch_id[i] == 0) //找寻一个空的
            {
                id = i;            //分配id
                touch_id[i] = 1;   //记录此置位已占用
                allocatedID_num++; //已分配计数+1
                break;
            }
        }
        if (id != -1)
        {
            SWITCH_ID_EVENT.value = id;
            DEFINE_UID_EVENT.value = 0xe2 + SWITCH_ID_EVENT.value;
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
    else if (type == MOUSE_REQUIRE) //鼠标固定为0
    {
        id = 0;
        SWITCH_ID_EVENT.value = id;
        DEFINE_UID_EVENT.value = 0xe2 + SWITCH_ID_EVENT.value;
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
    else if (type == WHEEL_REQUIRE) //移动固定为1
    {
        id = 1;
        SWITCH_ID_EVENT.value = id;
        DEFINE_UID_EVENT.value = 0xe2 + SWITCH_ID_EVENT.value;
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
    sem_post(&touch_dev_controler_sem_control);
    return id;
}

int ls_x_val = 0, ls_y_val = 0;
int ls_touch_start_x = 600, ls_touch_start_y = 600;
int ls_touch_last_x = -1, ls_touch_last_y = -1;
int ls_frequency = 500;
int ls_move_Range = 300;
void LS_manager() //左摇杆
{
    int LS_TOUCH_id = -1;
    while (Exclusive_mode_flag)
    {
        if (ls_x_val == 0 && ls_y_val == 0) //如果都为0 则不操作 并且，如果是按下状态就释放
        {                                   //死区的判定 在外部解决 ls_x_val = abs(ls_x_val)-2 >= 0 ? ls_x_val+-2 : 0;
            if (LS_TOUCH_id != -1)
            {
                touch_dev_controler(RELEASE_FLAG, LS_TOUCH_id, 0, 0);
                LS_TOUCH_id = -1;
            }
        }
        else //开始移动了
        {
            if (LS_TOUCH_id == -1)                                                                        //第一次按下 申请触摸
                LS_TOUCH_id = touch_dev_controler(WHEEL_REQUIRE, -1, ls_touch_start_x, ls_touch_start_y); //按下
            if (ls_x_val != ls_touch_last_x || ls_y_val != ls_touch_last_y)                               //与上次不同则移动
            {
                ls_touch_last_x = ls_x_val;
                ls_touch_last_y = ls_y_val;
                touch_dev_controler(MOVE_FLAG, LS_TOUCH_id, ls_touch_start_x + ls_x_val, ls_touch_start_y + ls_y_val);
            }
        }
        usleep(ls_frequency);
    }
    if (LS_TOUCH_id != -1)
    {
        touch_dev_controler(RELEASE_FLAG, LS_TOUCH_id, 0, 0);
        LS_TOUCH_id = -1;
    }
}

int rs_x_val = 0, rs_y_val = 0;
int rs_touch_start_x = 720, rs_touch_start_y = 1760;
int rs_touch_last_x = -1, rs_touch_last_y = -1;
int rs_frequency = 500;
int rs_speedRatio = 1;
void RS_manager() //右摇杆
{
    int RS_TOUCH_id = -1; //初始不按下
    rs_touch_last_x = rs_touch_start_x;
    rs_touch_last_y = rs_touch_start_y;
    while (Exclusive_mode_flag)
    {
        if (rs_x_val == 0 && rs_y_val == 0) //为0 不响应
        {
            if (RS_TOUCH_id != -1) //没有释放 则释放
            {
                touch_dev_controler(RELEASE_FLAG, RS_TOUCH_id, 0, 0);
                RS_TOUCH_id = -1;
                rs_touch_last_x = rs_touch_start_x;
                rs_touch_last_y = rs_touch_start_y; //相对位置归位
            }
        }
        else
        {
            if (RS_TOUCH_id == -1)
            {
                RS_TOUCH_id = touch_dev_controler(MOUSE_REQUIRE, -1, rs_touch_start_x, rs_touch_start_y);
            }

            int target_touch_x = rs_touch_last_x + rs_x_val;
            int target_touch_y = rs_touch_last_y + rs_y_val;
            if (target_touch_x < 32 || target_touch_x > rs_touch_start_x * 2 - 32 || target_touch_y < 32 || target_touch_y > (rs_touch_start_y - 200) * 2 - 32)
            {
                touch_dev_controler(RELEASE_FLAG, RS_TOUCH_id, 0, 0);                                     //松开
                RS_TOUCH_id = touch_dev_controler(MOUSE_REQUIRE, -1, rs_touch_start_x, rs_touch_start_y); //再按下
                target_touch_x = rs_touch_start_x + rs_x_val;
                target_touch_y = rs_touch_start_y + rs_y_val;
            }
            touch_dev_controler(MOVE_FLAG, RS_TOUCH_id, target_touch_x, target_touch_y);
            rs_touch_last_x = target_touch_x;
            rs_touch_last_y = target_touch_y;
        }
        usleep(rs_frequency);
    }
    if (RS_TOUCH_id != -1)
    {
        touch_dev_controler(RELEASE_FLAG, RS_TOUCH_id, 0, 0);
        RS_TOUCH_id = -1;
    }
}

int km_map_id[256 + 8];      //键盘鼠标code 对应分配的ID 按下获取并存入 释放的时候就从这里获取ID释放
                             //鼠标编码0x110开始 0~7个
                             //将其放在了一起 鼠标加偏移量256
int map_postion[256 + 8][2]; //映射的XY坐标
struct input_event joystick_queue[16];
int j_len = 0;
void handel_joystick_queue() // 注意  切换操作也在这里
//然后 范围计算转换 也在这里完成
//扳机按照数值不同 可以映射单独按键 需要记录last值以确定是进入范围还是离开范围
{
    // if (joystick_queue[0].type == EV_REL) ////鼠标移动
    // {
    //     if (mouse_touch_id == -1) //第一次移动  之后不再申请
    //     {
    //         mouse_touch_id = touch_dev_controler(REQURIE_FLAG, -1, mouse_Start_x, mouse_Start_y); //按下 获取ID 应该为0
    //         realtive_x = mouse_Start_x;
    //         realtive_y = mouse_Start_y; //相对X,Y
    //         return;
    //     }
    //     int x = 0;
    //     int y = 0;
    //     if (j_len == 3) //为3 则必定是X,Y
    //     {               //X和Y 顺序是固定的 先X 后y
    //         x = joystick_queue[0].value;
    //         y = joystick_queue[1].value;
    //     }
    //     else if (joystick_queue[0].code == REL_X)
    //     { //单个 x或y
    //         x = joystick_queue[0].value;
    //     }
    //     else if (joystick_queue[0].code == REL_Y)
    //     {
    //         y = joystick_queue[0].value;
    //     }
    //     else //这里可以处理滚轮事件
    //     {
    //         m_len = 0;
    //         return;
    //     }
    //     realtive_x -= y * mouse_speedRatio;
    //     realtive_y += x * mouse_speedRatio;
    //     if (realtive_x < 0 || realtive_x > mouse_Start_x * 2 || realtive_y < 0 || realtive_y > (mouse_Start_y - 200) * 2)
    //     {
    //         touch_dev_controler(RELEASE_FLAG, mouse_touch_id, 0, 0);                              //松开
    //         mouse_touch_id = touch_dev_controler(REQURIE_FLAG, -1, mouse_Start_x, mouse_Start_y); //再按下
    //         realtive_x = mouse_Start_x - y * mouse_speedRatio;
    //         realtive_y = mouse_Start_y + x * mouse_speedRatio; //相对X,Y
    //     }
    //     touch_dev_controler(MOVE_FLAG, mouse_touch_id, realtive_x, realtive_y); //移动
    // }
    // else //按键
    // {
    //     for (int i = 0; i < j_len; i++)
    //     {
    //         if (joystick_queue[i].type == EV_KEY && joystick_queue[i].code > 256) //鼠标按键
    //         {
    //             int mouse_code = 256 + joystick_queue[i].code - BTN_MOUSE; //0x110为左键 -0x110获得鼠标按键偏移
    //             if (joystick_queue[i].value == DOWN)
    //             {
    //                 km_map_id[mouse_code] = touch_dev_controler(REQURIE_FLAG, -1, map_postion[mouse_code][0], map_postion[mouse_code][1]);
    //             }
    //             else if (joystick_queue[i].value == UP)
    //             {
    //                 touch_dev_controler(RELEASE_FLAG, km_map_id[mouse_code], 0, 0);
    //             }
    //         }
    //         else if (joystick_queue[i].type == EV_KEY) //键盘按键
    //         {
    //             int keyCode = joystick_queue[i].code;
    //             int updown = joystick_queue[i].value;
    //             if (keyCode == KEY_GRAVE && updown == UP) //独占和非独占都关注 ` 用于切换状态  `键不响应键盘映射
    //             {
    //                 int tmp = Exclusive_mode_flag;
    //                 Exclusive_mode_flag = no_Exclusive_mode_flag;
    //                 no_Exclusive_mode_flag = tmp;
    //             }
    //             else if (Exclusive_mode_flag == 1)
    //             {
    //                 if (keyCode == KEY_W || keyCode == KEY_A || keyCode == KEY_S || keyCode == KEY_D) //方向键 额外处理
    //                     change_wheel_satuse(keyCode, updown);
    //                 else if (map_postion[keyCode][0] && map_postion[keyCode][1])
    //                 { //映射坐标不为0 设定映射
    //                     if (updown == DOWN)
    //                         km_map_id[keyCode] = touch_dev_controler(REQURIE_FLAG, -1, map_postion[keyCode][0], map_postion[keyCode][1]); //按下
    //                     else
    //                         touch_dev_controler(RELEASE_FLAG, km_map_id[keyCode], 0, 0); //释放
    //                 }
    //             }
    //         }
    //     }
    // }
    // j_len = 0;
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
    touch_fd = open(touch_dev_path, O_RDWR); //触摸设备号
    if (touch_fd < 0)
    {
        fprintf(stderr, "could not open touchScreen\n");
        int tmp = Exclusive_mode_flag;
        Exclusive_mode_flag = no_Exclusive_mode_flag;
        no_Exclusive_mode_flag = tmp; //切换回非独占
        return 1;
    }
    int rcode = 0;
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

    pthread_t rs_manager_thread;
    pthread_create(&rs_manager_thread, NULL, (void *)&RS_manager, NULL);

    pthread_t ls_manager_thread;
    pthread_create(&ls_manager_thread, NULL, (void *)&LS_manager, NULL);
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
    pthread_join(ls_manager_thread, NULL);
    pthread_join(rs_manager_thread, NULL);
    rcode = ioctl(joystick_dev_fd, EVIOCGRAB, 1);
    close(joystick_dev_fd);

    for (int i = 0; i < 10; i++)
        if (touch_id[i] != 0)
            touch_dev_controler(2, i, 0, 0); //释放所有按键
    SWITCH_ID_EVENT.value = 0xffff;
    allocatedID_num = 0;
    close(touch_fd);
    return 0;
}

int main(int argc, char *argv[]) //触屏设备号 键盘设备号 鼠标设备号 mapper映射文件路径 首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{
    int touch_dev_num = atoi(argv[1]);
    int joystick_dev_num = atoi(argv[2]);

    sprintf(touch_dev_path, "/dev/input/event%d", touch_dev_num);
    sprintf(joystick_dev_path, "/dev/input/event%d", joystick_dev_num);

    printf("Touch_dev_path:%s\n", touch_dev_path);
    printf("Joystick_dev_path:%s\n", joystick_dev_path);

    if (sem_init(&touch_dev_controler_sem_control, 0, 1) != 0)
    {
        perror("Fail to touch_dev_controler_sem_control init");
        exit(-1);
    }
    char buf[1024 * 8];      //配置文件大小最大8KB
    chdir(dirname(argv[0])); //设置当前目录为应用程序所在的目录
    printf("Reading config from %s\n", argv[4]);
    FILE *fp = fopen(argv[3], "r");
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

    rs_touch_start_x = config[0][0];
    rs_touch_start_y = config[0][1];
    rs_speedRatio = config[0][2];
    ls_touch_start_x = config[1][0];
    ls_touch_start_y = config[1][1];
    ls_move_Range = config[1][2];
    for (int i = 9; i < linecount; i++)
    {
        map_postion[config[i][0]][0] = config[i][1];
        map_postion[config[i][0]][1] = config[i][2];
    }
    while (1)
    {
        no_Exclusive_mode_JoyStick();
        Exclusive_mode_JoyStick(); //记得先插鼠标 再插键盘
    }
}

int test_main()
{
    if (sem_init(&touch_dev_controler_sem_control, 0, 1) != 0)
    {
        perror("Fail to touch_dev_controler_sem_control init");
        exit(-1);
    }
    sprintf(touch_dev_path, "/dev/input/event%d", 5);
    touch_fd = open(touch_dev_path, O_RDWR);
    if (touch_fd < 0)
    {
        fprintf(stderr, "could not open touchScreen\n");
        return 1;
    }
    Exclusive_mode_flag = 1;
    pthread_t rs_manager_thread;
    pthread_create(&rs_manager_thread, NULL, (void *)&RS_manager, NULL);

    pthread_t ls_manager_thread;
    pthread_create(&ls_manager_thread, NULL, (void *)&LS_manager, NULL);

    int offset = 10;
    // ls_y_val += offset;
    while (1)
    {
        ls_y_val += offset;
        ls_x_val += offset;
        if (ls_y_val > 400)
        {
            offset = -10;
        }
        if ((ls_y_val < -400))
        {
            offset = 10;
        }
        usleep(5000);
        // printf("%d\n", rs_x_val);
    }
    return 0;
}