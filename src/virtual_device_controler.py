import PyHook3
import pythoncom
import socket
import time

udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('192.168.1.231', 8848)

key_stause = [False for x in range(256)]


def onKeyboardEvent(event):
    if event.Key == "Escape":
        udpSocket.sendto("end".encode('utf-8'), sendArr)
        exit(0)
    if event.Message == 256 and key_stause[event.ScanCode] == False:
        key_stause[event.ScanCode] = True
        print("down")
        print(event.ScanCode)
        udpSocket.sendto(str(event.ScanCode*-1).encode('utf-8'), sendArr)
    elif event.Message == 257 and key_stause[event.ScanCode] == True:
        key_stause[event.ScanCode] = False
        print("up")
        print(event.ScanCode)
        udpSocket.sendto(str(event.ScanCode).encode('utf-8'), sendArr)

    return False


flag = False

lastx, lasty = 0, 0
startx, starty = 1481, 705
relativeX, relativeY = startx, starty


def onMouseEvent(event):
    global flag, lastx, lasty, startx, starty, relativeX, relativeY
    if "left down" in event.MessageName:
        lastx, lasty = event.Position
        relativeX, relativeY = startx, starty
        flag = True
        return True
    if "left up" in event.MessageName:
        flag = False
        return True
    if(flag):
        x, y = event.Position
        relativeX -= (x-lastx)
        relativeY += (y-lasty)
        if(relativeX not in range(50, 3000) or relativeY not in range(34, 1300)):
            flag = False
            relativeX, relativeY = startx, starty
            flag = True
        else:
            pass
            print(relativeX, relativeY)

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
