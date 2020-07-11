# exclusive_mode_mapper
## 在系统底层实现鼠标键盘映射触屏
## PS: 没ROOT可以不看了
# 说明
> ### 安卓的底层Linux通过/dev/input/eventX来实现对输入输出设备的管理
> ### root后可以直接对字符设备进行读写
> ### 程序工作时使用独占模式，读取键盘鼠标的输入，通过写设备文件映射操作到触屏
> ### 使用~键在键鼠正常使用和程序独占映射模式之间切换 
# 优点
> ### 在Linux底层完成映射，延迟级低。
> ### 不运行安卓程序，无法被检测。
# 缺点
> ### 需要ROOT权限
# 使用方法
> ### 拷贝exclusive_mode_mapper.c到安卓终端内
> ### 执行 gcc exclusive_mode_mapper.c -o exc;sudo exc /dev/input/event5
# 注意
> ### 不同的手机型号对应的输入输出event不尽相同，可能需要自行修改event数字
> ### 通过getevent能看到自己的键盘鼠标设备号
> ### 键盘鼠标插入顺序决定序号
# To Do
> * ### 添加读取配置文件功能
> * ### 通过PC或者直接在手机创建配置文件
