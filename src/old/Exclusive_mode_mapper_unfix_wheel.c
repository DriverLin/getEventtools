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

#define keyboard_dev 16
#define keyboard_device_path "/dev/input/event16"
#define mouse_dev 15
#define mouse_device_path "/dev/input/event15"
#define DOWN 0x1
#define UP 0x0
#define ABS_MT_TRACKING_ID 0x39
#define ABS_MT_POSITION_X 0x35
#define ABS_MT_POSITION_Y 0x36

int touch_fd;                   //event5 触屏的设备指针
int Exclusive_mode_flag = 0;    //独占模式标识
int no_Exclusive_mode_flag = 1; //刚开始 进入非独占模式
struct input_event m_q[16];     //鼠标信号队列
int m_len = 0;                  //队列长度
struct input_event k_q[16];     //键盘信号队列
int k_len = 0;                  //键盘队列长度

int touch_id[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int postion[10][2];
int allocatedID_num = 0;

struct input_event signal_sync = {0, EV_SYN, SYN_REPORT, 0}; //同步 最常用的 直接用
struct input_event btn_down = {0, EV_KEY, BTN_TOUCH, DOWN};  //按下 没有触摸点的时候使用
struct input_event btn_up = {0, EV_KEY, BTN_TOUCH, DOWN};    //释放 触摸点全部释放的时候使用
//type = 0,1,2 id = -1,.... ,x,y      ID为-1 则是按下，获取返回的ID，下次带上才可进行滑动或者释放操作
//x,y为绝对坐标 越界重置也由外部完成
//按下 移动 释放
//滑动 = 按下+移动+释放
//不提供点击功能
//点击 = 按下 + 释放
//超出10点个不响应
//返回触摸点的ID 下次带上
//鼠标的映射 鼠标一开始就占一个 切换后才释放 是申请还是移动 在外边判断
int mapper(int type, int unclear_id, int x, int y)
{
    // printf("%d\t%d\t%d\t%d\n", type, unclear_id, x, y);

    struct input_event sync; //同步 直接用
    sync.type = 0;
    sync.code = 0;
    sync.value = 0;

    struct input_event set_id; //切换触摸点 修改value再用
    set_id.type = 3;
    set_id.code = 0x2f;
    set_id.value = 0;

    struct input_event pos_x; //X坐标
    pos_x.type = 3;
    pos_x.code = 0x35;
    pos_x.value = 0;

    struct input_event pos_y; //Y坐标
    pos_y.type = 3;
    pos_y.code = 0x36;
    pos_y.value = 0;

    struct input_event defineUID; //声明识别ID 用于消除
    defineUID.type = 3;
    defineUID.code = 0x39;
    defineUID.value = 0;

    struct input_event down; //按下 没有触摸点的时候使用
    down.type = 1;
    down.code = 0x14a;
    down.value = 0x1;

    struct input_event up; //释放 触摸点全部释放的时候使用
    up.type = 1;
    up.code = 0x14a;
    up.value = 0x0;

    int id = unclear_id;
    if (type == 0) //移动:  切换ID,X,Y,同步 编码格式 "2 id x y"
    {
        set_id.value = id;
        pos_x.value = x;
        pos_y.value = y;
        write(touch_fd, &set_id, sizeof(set_id));
        write(touch_fd, &pos_x, sizeof(pos_x));
        write(touch_fd, &pos_y, sizeof(pos_y));
        write(touch_fd, &sync, sizeof(sync));
    }
    else if (type == 2) //释放: 切换ID,uid=-1,同步 编码格式 "1 id"
    {
        touch_id[id] = 0;  // 释放
        allocatedID_num--; //占用数目-1
        set_id.value = id;
        defineUID.value = 0xffffffff;
        write(touch_fd, &set_id, sizeof(set_id));
        write(touch_fd, &defineUID, sizeof(defineUID));
        if (allocatedID_num == 0) //为0 全部释放 btn up
            write(touch_fd, &up, sizeof(up));
        write(touch_fd, &sync, sizeof(sync));
    }
    else if (type == 1)
    {                 //type == pressTouch  按下： 切换ID，uid=自定义，x，y，同步 编码格式 "0 id x y"
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
        if (id == -1) //分配失败 下次再说
            return -1;

        set_id.value = id;
        defineUID.value = 0xe2 + set_id.value;
        pos_x.value = x;
        pos_y.value = y;
        write(touch_fd, &set_id, sizeof(set_id));
        write(touch_fd, &defineUID, sizeof(defineUID));
        if (allocatedID_num == 1) //为1 则是头一次按下 btn down
            write(touch_fd, &down, sizeof(down));
        write(touch_fd, &pos_x, sizeof(pos_x));
        write(touch_fd, &pos_y, sizeof(pos_y));
        write(touch_fd, &sync, sizeof(sync));
    }
    return id;
}

int first_mouse_touch_id = -1; //鼠标映射的ID 唯一 第一次产生移动事件时按下 之后只有移动  切换映射的时候才释放
int mouse_Start_x = 720;       ///开始结束坐标 只读
int mouse_Start_y = 1600;      //中途可能有切换 还是会回到这里的
int realtive_x, realtive_y;    //保存当前移动坐标
int mouse_speedRatio = 1;
int km_map_id[256 + 16];      //键盘code 对应分配的ID 按下获取 然后存入 释放的时候就从这里获取ID释放
                              //鼠标 鼠标按键还是挺多的 但是似乎编码不友好 所以是手动判断的重新编码的
                              //将其放在了一起 鼠标加偏移量256
int map_postion[256 + 16][2]; //映射的XY坐标

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

        if (first_mouse_touch_id == -1)
        {
            first_mouse_touch_id = mapper(1, first_mouse_touch_id, mouse_Start_x, mouse_Start_y); //按下 获取ID 应该为0
            realtive_x = mouse_Start_x;
            realtive_y = mouse_Start_y; //相对X,Y
            return;
        }
        realtive_x -= y * mouse_speedRatio;
        realtive_y += x * mouse_speedRatio;
        if (realtive_x < 100 || realtive_x > 1400 || realtive_y < 100 || realtive_y > 3000)
        {
            mapper(2, first_mouse_touch_id, 0, 0);
            first_mouse_touch_id = -1;                                                            //松开
            first_mouse_touch_id = mapper(1, first_mouse_touch_id, mouse_Start_x, mouse_Start_y); //再按下
            realtive_x = mouse_Start_x;
            realtive_y = mouse_Start_y; //相对X,Y
        }

        mapper(0, first_mouse_touch_id, realtive_x, realtive_y); //移动
        // printf("[%d,%d]\n", realtive_x, realtive_y);
    }
    else if (m_q[0].type == EV_MSC) //点击
    {
        int mouse_code;
        if (m_q[1].code == BTN_MOUSE) //左键
            mouse_code = 0;
        else if (m_q[1].code == BTN_RIGHT) //右键
            mouse_code = 1;
        if (m_q[1].value == DOWN) //按下
        {
            km_map_id[256 + mouse_code] = mapper(1, -1, map_postion[256 + mouse_code][0], map_postion[256 + mouse_code][1]);
        }
        else if (m_q[1].value == UP) //释放
        {
            mapper(2, km_map_id[256 + mouse_code], 0, 0);
        }
    }
    m_len = 0;
    return;
}

int wheel_satuse[4];                                                                                                                    //默认为0 初始化时和结束时也手动清0
int wheel_postion[9][2] = {{300, 300}, {600, 300}, {900, 300}, {300, 600}, {600, 600}, {900, 600}, {300, 900}, {600, 900}, {900, 900}}; //8个状态的坐标
int wheel_ID = -1;
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
    // printf("[%d,%d,%d,%d]\n", wheel_satuse[0], wheel_satuse[1], wheel_satuse[2], wheel_satuse[3]);
    // printf("x=%d,y=%d\n", x_Asix - 1, y_Asix - 1);
    // printf("map_value=%d\n", map_value);
    // return;
    // printf("当前状态数组下标为%d\n", map_value);
    if (last_map_value == 4 && map_value != 4) //开始 先按下 再移动
    {
        wheel_ID = mapper(1, -1, wheel_postion[4][0], wheel_postion[4][1]);            //
        mapper(0, wheel_ID, wheel_postion[map_value][0], wheel_postion[map_value][1]); //移动
    }
    else
    {
        if (map_value != 4)
        {

            mapper(0, wheel_ID, wheel_postion[map_value][0], wheel_postion[map_value][1]); //正常移动
        }
        else
        {
            mapper(2, wheel_ID, 0, 0); //释放
            wheel_ID = -1;
        }
    }
}

void handel_k_q() //处理键盘动作
{
    int keyCode = k_q[k_len - 2].code;
    int updown = k_q[k_len - 2].value;
    if (keyCode == KEY_GRAVE) //独占和非独占都关注 ` 用于切换状态  `键不响应键盘映射
    {
        if (updown == UP)
        {
            printf("切换独占状态\n");
            int tmp = Exclusive_mode_flag;
            Exclusive_mode_flag = no_Exclusive_mode_flag;
            no_Exclusive_mode_flag = tmp;
        }
    }
    else if (Exclusive_mode_flag == 1)
    { //独占模式下 才会处理其他信号 非独占不处理
        // printf("{ code = %d , UD = %d }\n", keyCode, updown);
        // map_postion[keyCode][0] = 800 + keyCode;
        // map_postion[keyCode][1] = 900 + keyCode;
        if (keyCode == KEY_W || keyCode == KEY_A || keyCode == KEY_S || keyCode == KEY_D) //方向键 额外处理
        {
            change_wheel_satuse(keyCode, updown);
        }
        else if (map_postion[keyCode][0] && map_postion[keyCode][1]) //映射坐标不为0 设定映射
        {
            if (updown == DOWN)
            {
                km_map_id[keyCode] = mapper(1, -1, map_postion[keyCode][0], map_postion[keyCode][1]); //按下
            }
            else
            {
                mapper(2, km_map_id[keyCode], 0, 0); //释放
            }
        }
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
        {
            handel_m_q();
        }
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

int Exclusive_mode(char *argv[])
{
    touch_fd = open(argv[1], O_RDWR);
    for (int i = 0; i < 4; i++)
        wheel_satuse[i] = 0; //清除方向盘状态

    if (touch_fd < 0)
    {
        fprintf(stderr, "could not open %s, %s\n", argv[optind], strerror(errno));
        printf("进入失败 无法打开event");
        int tmp = Exclusive_mode_flag;
        Exclusive_mode_flag = no_Exclusive_mode_flag;
        no_Exclusive_mode_flag = tmp;
        return 1;
    }

    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open(keyboard_device_path, O_RDONLY | O_NONBLOCK);
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
    int mouse_fd = open(mouse_device_path, O_RDONLY | O_NONBLOCK);
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

    /*
    检查所有触摸点
    手动释放所有的点
    first_mouse_touch_id = -1;
    */
    for (int i = 0; i < 4; i++)
        wheel_satuse[i] = 0; //清除方向盘状态
    for (int i = 0; i < 10; i++)
    {
        if (touch_id[i] != 0)
        {
            mapper(2, i, 0, 0); //释放所有按键
        }
    }

    first_mouse_touch_id = -1;
    close(touch_fd);

    return 0;
}

int no_Exclusive_mode()
{

    int rcode = 0;
    char keyboard_name[256] = "Unknown";
    int keyboard_fd = open(keyboard_device_path, O_RDONLY | O_NONBLOCK);
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

void rset_global()
{
    m_len = 0;
    k_len = 0;
    allocatedID_num = 0;
    first_mouse_touch_id = -1;
    wheel_ID = -1;
}

int main(int argc, char *argv[]) //首先是非独占模式 由`键启动进入独占模式 独占模式也可以退出到非独占 非独占只关注`键
{

    char buf[1024 * 8];      //配置文件大小最大8KB
    chdir(dirname(argv[0])); //设置当前目录为应用程序所在的目录
    printf("reading config from %s...\n", argv[2]);
    FILE *fp = fopen(argv[2], "r");
    if (fp == NULL)
    {
        fprintf(stderr, "could not open %s, %s\n", argv[2], strerror(errno));
        printf("Can't read map file\n");
        return 1;
    }
    fread(buf, 1024 * 8, 1, fp);
    fclose(fp);
    int linecount = 0;
    char lines[68][64]; //总共支持的最长映射为67个
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
        Exclusive_mode(argv); //记得先插鼠标 再插键盘
        rset_global();
    }
}
