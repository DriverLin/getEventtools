# getEventtools
### 通过直接读写/dev/input/eventX实现对android的操控
#### 没ROOT可以不看了
# 说明
### getevent可以获取/dev/input/eventX的输出
### sendEvent可以输入控制。
### 通过在android终端运行一个程序对/dev/input/eventX打开进行持续读写来实现。
### ~~PC上使用python脚本采集鼠标键盘信号，处理后发送实现控制。~~
### 直接连接鼠标键盘，读取event信号，输出触摸信号
### 支持在正常使用和独占模式之间切换

# 使用方法
### 手机上gcc编译。SU，运行程序
### 不同的手机型号对应的输入输出event不尽相同，可能需要自行修改event数字
### 键盘鼠标插入顺序决定序号
### 以后考虑添加自动识别代码