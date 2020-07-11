import PyHook3
import pythoncom
import socket
import time

udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('192.168.3.8', 8848)
# sendArr = ('192.168.137.55', 8848)

# 目前只考虑写入到event5 电源键对event0 音量对event9


# # while True:


def clickOnce(click_x, click_y):
    udpSocket.sendto("0 0 {} {} ".format(
        click_x, click_y).encode('utf-8'), sendArr)

    time.sleep(0.01)
    for i in range(10):
        udpSocket.sendto("2 0 {} {} ".format(
            click_x+i*2, click_y+i*2).encode('utf-8'), sendArr)
        time.sleep(0.1)

    udpSocket.sendto("1 0".encode('utf-8'), sendArr)


def onKeyboardEvent(event):
    if event.Key == "Escape":
        # udpSocket.sendto("end".encode('utf-8'), sendArr)
        exit(0)
    if event.Message == 256:
        print("应该发送了。。。")
        clickOnce(1480, 700)

    return True


flag = False

lastx, lasty = 0, 0
startx, starty = 1481, 705
relativeX, relativeY = startx, starty


keyWheel = []


def onMouseEvent(event):
    global flag, lastx, lasty, startx, starty, relativeX, relativeY
    if "left down" in event.MessageName:
        udpSocket.sendto("0 0 {} {} ".format(
            startx, starty).encode('utf-8'), sendArr)
        lastx, lasty = event.Position
        relativeX, relativeY = startx, starty
        flag = True
        return True
    if "left up" in event.MessageName:
        flag = False
        udpSocket.sendto("1 0".encode('utf-8'), sendArr)
        return True
    if(flag):
        x, y = event.Position
        relativeX -= (x-lastx)
        relativeY += (y-lasty)
        if(relativeX not in range(50, 3000) or relativeY not in range(34, 1300)):
            flag = False
            udpSocket.sendto("1 0".encode('utf-8'), sendArr)
            udpSocket.sendto("0 0 {} {} ".format(
                startx, starty).encode('utf-8'), sendArr)
            relativeX, relativeY = startx, starty
            flag = True
        else:
            udpSocket.sendto("2 0 {} {} ".format(
                relativeY, relativeX).encode('utf-8'), sendArr)
        # print(relativeX, relativeY)

        return False
    return True


def main():
        # 创建管理器
    hm = PyHook3.HookManager()
    # 监听键盘
    hm.KeyDown = onKeyboardEvent
    hm.KeyUp = onKeyboardEvent
    hm.HookKeyboard()
    # 监听鼠标
    hm.MouseAll = onMouseEvent
    hm.HookMouse()
    # 循环监听
    pythoncom.PumpMessages()


if __name__ == "__main__":
    main()
