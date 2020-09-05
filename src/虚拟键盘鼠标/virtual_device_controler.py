import PyHook3
import pythoncom
import socket
import time
import _thread
udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('127.0.0.1', 8848)

key_stause = [False for x in range(256)]

Exclusive_mode = True


def onKeyboardEvent(event):
    global Exclusive_mode, firstFlag
    if event.Key == "Escape" and event.Message == 257:
        Exclusive_mode = not Exclusive_mode
        # firstFlag = True
        return True
    if Exclusive_mode == False:
        return True
    if event.Message == 256 and key_stause[event.ScanCode] == False:
        key_stause[event.ScanCode] = True
        udpSocket.sendto(
            str(event.ScanCode+100000000).encode('utf-8'), sendArr)
    elif event.Message == 257 and key_stause[event.ScanCode] == True:
        key_stause[event.ScanCode] = False
        udpSocket.sendto(
            str(event.ScanCode+200000000).encode('utf-8'), sendArr)

    return False


start_x, start_y = -1, -1
firstFlag = True
relativeX, relativeY = 0, 0

mulx = 0
muly = 0


def onMouseEvent(event):
    global start_x, start_y, firstFlag, Exclusive_mode, mulx, muly
    if Exclusive_mode == False:
        start_x, start_y = event.Position
        return True
    if firstFlag:
        firstFlag = False
        start_x, start_y = event.Position
        return False
    currentx, currenty = event.Position
    relativeX = (currentx - start_x)
    relativeY = (currenty - start_y)
    mulx += relativeX
    muly += relativeY
    # print(mulx, muly)
    # print("\r",relativeX,relativeY);
    if(relativeX != 0 or relativeY != 0):
        udpSocket.sendto(str((100000000+relativeX*10000) % 100000000 +
                             (relativeY+10000) % 10000).encode('utf-8'), sendArr)
    # print(event.MessageName)
    mapper = {
        "mouse left up": 272+200000000,
        "mouse left down": 272+100000000,
        "mouse right down": 273+100000000,
        "mouse right up": 273+200000000,
        "mouse middle down": 274+100000000,
        "mouse middle up": 274+200000000,
    }
    if event.MessageName in mapper:
        udpSocket.sendto(
            str(mapper[event.MessageName]).encode('utf-8'), sendArr)
    return False


lastMul = (0, 0)
lastSpeed = (0, 0)


def tojs():
    return False
    global lastMul, lastSpeed
    while True:
        time.sleep(0.001)
        v_x = mulx - lastMul[0]
        v_y = muly - lastMul[1]
        if (v_x, v_y) == lastSpeed:
            continue
        else:
            lastMul = (mulx, muly)
            lastSpeed = (v_x, v_y)
            print(v_x, v_y)
            udpSocket.sendto(str((100000000+v_x*10000) % 100000000 +
                                 (v_y+10000) % 10000).encode('utf-8'), sendArr)
    pass


def main():
    hm = PyHook3.HookManager()
    hm.KeyDown = onKeyboardEvent
    hm.KeyUp = onKeyboardEvent
    hm.HookKeyboard()
    hm.MouseAll = onMouseEvent
    hm.HookMouse()
    _thread.start_new_thread(tojs, ())
    pythoncom.PumpMessages()


if __name__ == "__main__":
    main()
