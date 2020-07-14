# Exclusive_mode_mapper
在系统底层实现鼠标键盘映射触屏
## 说明
安卓的底层Linux通过/dev/input/eventX来实现对输入输出设备的管

root后可以直接对字符设备进行读写

程序工作时使用独占模式，读取键盘鼠标的输入，通过写设备文件映射操作到触屏

使用~键在键鼠正常使用和程序独占映射模式之间切换 

## 优点
在Linux底层完成映射，延迟级低。

不运行安卓程序，无法被检测。
## 缺点
需要ROOT权限
## 使用方法

下载
```
wget https://raw.githubusercontent.com/DriverLin/Exclusive_mode_mapper/master/src/mapper.c
```
编译
```
gcc mapper.c -o mapper
```
查看自己的触屏，鼠标和，键盘对应的设备号

获取脚本文件

执行
```
sudo ./mapper 触屏设备号 鼠标设备号 键盘设备号 映射文件路径
```
例如
``` 
$ sudo ./mapper 5 15 16 ./hpjy_br.mapper
touch_dev_path:/dev/input/event5
mouse_dev_path:/dev/input/event15
keyboard_dev_path:/dev/input/event16
reading config from ./hpjy_br.mapper...
Reading From : HID 046a:0011
```

## 关于脚本
截图保存 create_mapper/sc.jpg

使用create_mapper/getMapper.html创建JSON格式

使用transform脚本转换为mapper格式


