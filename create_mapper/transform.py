import os
import json
linux_map = {
    "Key_Backspace": 14,
    "Key_Tab": 15,
    "Key_Clear": 0,
    "Key_Enter": 28,
    "Key_Shift": 42,
    "Key_Control": 29,
    "Key_Alt": 56,
    "Key_Pause": 119,
    "Key_CapsLock": 58,
    "Key_Escape": 1,
    "Key_Space": 57,
    "Key_Home": 102,
    "Key_Left": 105,
    "Key_Up": 103,
    "Key_Right": 106,
    "Key_Down": 108,
    "Key_Print": 210,
    "Key_Insert": 110,
    "Key_Delete": 111,
    "Key_0": 11,
    "Key_1": 2,
    "Key_2": 3,
    "Key_3": 4,
    "Key_4": 5,
    "Key_5": 6,
    "Key_6": 7,
    "Key_7": 8,
    "Key_8": 9,
    "Key_9": 10,
    "Key_A": 30,
    "Key_B": 48,
    "Key_C": 46,
    "Key_D": 32,
    "Key_E": 18,
    "Key_F": 33,
    "Key_G": 34,
    "Key_H": 35,
    "Key_I": 23,
    "Key_J": 36,
    "Key_K": 37,
    "Key_L": 38,
    "Key_M": 50,
    "Key_N": 49,
    "Key_O": 24,
    "Key_P": 25,
    "Key_Q": 16,
    "Key_R": 19,
    "Key_S": 31,
    "Key_T": 20,
    "Key_U": 22,
    "Key_V": 47,
    "Key_W": 17,
    "Key_X": 45,
    "Key_Y": 21,
    "Key_Z": 44,
    "Key_NumLock": 69,
    "Key_ScrollLock": 70,
    "LeftButton": 256,
    "RightButton": 257  # 自定义左右键
}

wheel_postion = []
x_len = int(input("x长度:"))
y_len = int(input("y长度"))
jsonpath = input("jsonpath:")
config = ""
"""
起始x,y,speedRatio
方向盘9个x,y
code,x,y
"""


with open(jsonpath) as j:
    qtscrcpy_map = (json.load(j))
    mouse_start_x = int(
        float(qtscrcpy_map["mouseMoveMap"]["startPos"]["x"]) * x_len)
    mouse_start_y = int(
        float(qtscrcpy_map["mouseMoveMap"]["startPos"]["y"]) * y_len)
    speedRatio = int(qtscrcpy_map["mouseMoveMap"]["speedRatio"])
    if(speedRatio == 0):
        speedRatio = 1
    config += str(mouse_start_x)+" "+str(mouse_start_y) + \
        " "+str(speedRatio)+"\n"
    for node in qtscrcpy_map["keyMapNodes"]:
        if(node["type"] == "KMT_STEER_WHEEL"):
            x = int(float(node["centerPos"]["x"]) * x_len)
            y = int(float(node["centerPos"]["y"]) * y_len)
            offset = int(float(node["upOffset"]) * y_len)
            if(x-offset <= 0 or y - offset <= 0):
                offset = min(x, y) - 100
            config += "0 "+str(x-offset)+" "+str(y-offset)+"\n"
            config += "1 "+str(x)+" "+str(y-offset)+"\n"
            config += "2 "+str(x+offset)+" "+str(y-offset)+"\n"
            config += "3 "+str(x-offset)+" "+str(y)+"\n"
            config += "4 "+str(x)+" "+str(y)+"\n"
            config += "5 "+str(x+offset)+" "+str(y)+"\n"
            config += "6 "+str(x-offset)+" "+str(y+offset)+"\n"
            config += "7 "+str(x)+" "+str(y+offset)+"\n"
            config += "8 "+str(x+offset)+" "+str(y+offset)+"\n"
    for node in qtscrcpy_map["keyMapNodes"]:
        if(node["type"] == "KMT_CLICK"):
            key_code = linux_map[node["key"]]
            x = int(float(node["pos"]["x"]) * x_len)
            y = int(float(node["pos"]["y"]) * y_len)
            config += str(key_code)+" "+str(x)+" "+str(y)+"\n"
print("["+config+"]")
outPath = os.path.splitext(jsonpath)[0]+".mapper"
print(outPath)
with open(outPath, 'w') as f:
    f.write(config)
