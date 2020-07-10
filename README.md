# getEventtools
### 通过直接读写/dev/input/eventX实现对android的操控
#### 没ROOT可以不看了
# 说明
### getEvent和sendEvent可以获取触屏的输入以及对其进行控制。
### 使用简单的程序，可以实现与sendEvent相同的功能而不会有sendEvent这么大的延迟。
### 通过在android终端运行一个程序对/dev/input/eventX打开进行持续读写来实现。用过socket接受远端控制信号，对eventX文件持续写入。 
### PC上使用python脚本采集鼠标键盘信号，处理后发送实现控制。

# 使用方法
### 将c程序拷贝到android具有运行权限的目录下，编译，使用su运行。
### PC机上修改python脚本中IP，即可实现控制