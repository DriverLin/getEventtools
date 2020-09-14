# Exclusive_mode_mapper
在系统底层实现鼠标键盘映射触屏
## 说明
安卓的底层Linux通过/dev/input/eventX来实现对输入输出设备的管理。

root后可以直接对字符设备进行读写。

程序工作时使用独占模式，读取键盘鼠标的输入，通过写设备文件映射操作到触屏。

使用~键在键鼠正常使用和程序独占映射模式之间切换 。

## 优点
在Linux底层完成映射，延迟低。
## 缺点
需要ROOT权限。
## 使用方法
查看自己的触屏鼠标和键盘对应的设备号。
```
sudo getevent -l
```

下载
```
wget https://raw.githubusercontent.com/DriverLin/Exclusive_mode_mapper/master/src/mapper.c
```
编译
```
gcc mapper.c -o mapper
```
执行
```
sudo ./mapper 触屏设备号 鼠标设备号 键盘设备号 映射文件路径
```
输出看起来应该是这样的
``` 
$ sudo ./mapper 5 15 16 ./hpjy_br.mapper
Touch_dev_path:/dev/input/event5
Mouse_dev_path:/dev/input/event15
Keyboard_dev_path:/dev/input/event16
Reading config from ./hpjy_br.mapper
Reading From : HID 046a:0011
```
按～键开关映射

## 关于映射文件

[创建映射文件](https://driverlin.github.io/Exclusive_mode_mapper/)

按住键盘按键点击对应位置即可生成并自动复制到剪贴板

数字键8,9,0对应鼠标左中右键

S用于定位摇杆中心

W用于限制摇杆范围


## 手柄部分
mapper文件参照input.h填写

键值为 ```REAL_KEYCODE - 0X130```

select+RS切换

## 手柄配置文件
```
startx starty moveSpeedRange //触摸起始 移动速度范围
wheel_startx wheel_start_y moveRange //wheel起始 移动范围
ID X Y //keycode-0X130 按下坐标
ID X Y
```
