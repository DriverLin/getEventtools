import socket
import time

BTN_GAMEPAD = 0x130
BTN_SOUTH = 0x130
BTN_A = BTN_SOUTH
BTN_EAST  =  0x131
BTN_B = BTN_EAST
BTN_C = 0x132
BTN_NORTH = 0x133
BTN_X = BTN_NORTH
BTN_WEST  =  0x134
BTN_Y = BTN_WEST
BTN_Z = 0x135
BTN_TL = 0x136
BTN_TR = 0x137
BTN_TL2 = 0x138
BTN_TR2 = 0x139
BTN_SELECT = 0x13a
BTN_START = 0x13b
BTN_MODE  =  0x13c
BTN_THUMBL = 0x13d
BTN_THUMBR = 0x13e
ABS_X = 0x00
ABS_Y = 0x01
ABS_Z = 0x02
ABS_RX = 0x03
ABS_RY = 0x04
ABS_RZ = 0x05
ABS_THROTTLE = 0x06
ABS_RUDDER = 0x07
ABS_WHEEL = 0x08
ABS_GAS = 0x09
ABS_BRAKE = 0x0a
ABS_HAT0X = 0x10
ABS_HAT0Y = 0x11
ABS_HAT1X = 0x12
ABS_HAT1Y = 0x13
ABS_HAT2X = 0x14
ABS_HAT2Y = 0x15
ABS_HAT3X = 0x16
ABS_HAT3Y = 0x17
ABS_PRESSURE = 0x18
ABS_DISTANCE = 0x19
ABS_TILT_X = 0x1a
ABS_TILT_Y = 0x1b
ABS_TOOL_WIDTH = 0x1c



udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('192.168.137.2', 8848)


def sendData(code, x_value, y):
    n = 0x0
    n += code
    n *= 0x10000
    n += x_value
    n *= 0x10000
    n += y
    udpSocket.sendto(n.to_bytes(
        length=6, byteorder='big', signed=False), sendArr)


if __name__ == "__main__":

    #方向键测试
    sendData(ABS_HAT0X, 0x0, 0x0)
    time.sleep(0.5)
    sendData(ABS_HAT0X, 0x2, 0x0)
    time.sleep(0.5)
    sendData(ABS_HAT0X, 0x1, 0x0)
    time.sleep(0.1)
    sendData(ABS_HAT0Y, 0x0, 0x0)
    time.sleep(0.5)
    sendData(ABS_HAT0Y, 0x2, 0x0)
    time.sleep(0.5)
    sendData(ABS_HAT0Y, 0x1, 0x0)

    #轴测试
    for i in range(0,0xff):
        sendData(ABS_X,i*0x100,0x7fff)
        time.sleep(0.01)
    for i in range(0,0xff):
        sendData(ABS_X,0x7fff,i*0x100)
        time.sleep(0.01)
    sendData(ABS_X,0x7fff,0x7fff)
    for i in range(0,0xff):
        sendData(ABS_Z,i*0x100,0x7fff)
        time.sleep(0.01)
    for i in range(0,0xff):
        sendData(ABS_Z,0x7fff,i*0x100)
        time.sleep(0.01)
    sendData(ABS_Z,0x7fff,0x7fff)
    
    #扳机测试
    for i in range(0,0x3f):
        sendData(ABS_BRAKE,i*0x10+0xf, 0x0)
        time.sleep(0.01)

    for i in range(0,0x3f):
        sendData(ABS_GAS,i*0x10+0xf, 0x0)
        time.sleep(0.01)

    for i in range(0,0x3f):
        sendData(ABS_GAS,0x3ff - i*0x10+0xf, 0x0)
        time.sleep(0.01)

    for i in range(0,0x3f):
        sendData(ABS_BRAKE,0x3ff - i*0x10+0xf, 0x0)
        time.sleep(0.01)
    
    #按键测试
    for i in [BTN_GAMEPAD,BTN_EAST,BTN_NORTH,BTN_WEST,BTN_TL,BTN_TR,BTN_THUMBL,BTN_THUMBR,BTN_SELECT,BTN_START]:
        sendData(i,0x1,0xffff)
        time.sleep(0.5)
        sendData(i,0x0,0xffff)
        time.sleep(0.1)

    

    

    
