import time
import socket


EV_ABS = 0x3
EV_KEY = 0x1
EV_SYN = 0x0
ABS_MT_TRACKING_ID = 0x39
BTN_TOUCH = 0x14a
SYN_REPORT = 0x0
ABS_MT_POSITION_X = 0x35
ABS_MT_POSITION_Y = 0x36
DOWN = 0x1
UP = 0x0


down = [
    (EV_ABS, ABS_MT_TRACKING_ID, 0x0000b4e0),
    (EV_KEY, BTN_TOUCH, DOWN),
    (EV_ABS, ABS_MT_POSITION_X, 100),
    (EV_ABS, ABS_MT_POSITION_Y, 2000),
    (EV_SYN, SYN_REPORT, 0x00000000)
]

up = [
    (EV_ABS, ABS_MT_TRACKING_ID, 0xffffffff),
    (EV_KEY, BTN_TOUCH, UP),
    (EV_SYN, SYN_REPORT, 0x00000000)
]


def get_command(tup):
    return str(tup[0])+" " + str(tup[1]) + " " + str(tup[2])


def create_move(x, y):
    list = []
    for c in [(EV_ABS, ABS_MT_POSITION_X, x),
              (EV_ABS, ABS_MT_POSITION_Y, y),
              (EV_SYN, SYN_REPORT, 0x00000000)]:
        list.append(get_command(c))
    return list


testList_List = []


downList = []
for c in down:
    downList.append(get_command(c))
testList_List.append(downList)


x = 100
y = 2000
for i in range(500):
    x += 0
    y += 1
    testList_List.append(create_move(x, y))

upList = []
for c in up:
    upList.append(get_command(c))
testList_List.append(upList)

# print(testList)


udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('192.168.3.8', 8848)
for commands in testList_List:
    # udpSocket.sendto(command.encode('utf-8'), sendArr)
    # time.sleep(0.007)
    for single in commands:
        udpSocket.sendto(single.encode('utf-8'), sendArr)
    time.sleep(0.008)
