var dowing = false
var dowKey 
var list = {}
var kmap = {
    8: "Key_Backspace",
    9: "Key_Tab",
    12: "Key_Clear",
    13: "Key_Enter",
    16: "Key_Shift",
    17: "Key_Control",
    18: "Key_Alt",
    19: "Key_Pause",
    20: "Key_CapsLock",
    27: "Key_Escape",
    32: "Key_Space",
    34: "Key_MediaNext",
    35: "Key_Hangul_End",
    36: "Key_Home",
    37: "Key_Left",
    38: "Key_Up",
    39: "Key_Right",
    40: "Key_Down",
    41: "Key_Select",
    42: "Key_Print",
    43: "Key_Execute",
    45: "Key_Insert",
    46: "Key_Delete",
    47: "Key_Help",
    48: "Key_0",
    49: "Key_1",
    50: "Key_2",
    51: "Key_3",
    52: "Key_4",
    53: "Key_5",
    54: "Key_6",
    55: "Key_7",
    56: "Key_8",
    57: "Key_9",
    96: "Key_0",
    97: "Key_1",
    98: "Key_2",
    99: "Key_3",
    100: "Key_4",
    101: "Key_5",
    102: "Key_6",
    103: "Key_7",
    104: "Key_8",
    105: "Key_9",
    65: "Key_A",
    66: "Key_B",
    67: "Key_C",
    68: "Key_D",
    69: "Key_E",
    70: "Key_F",
    71: "Key_G",
    72: "Key_H",
    73: "Key_I",
    74: "Key_J",
    75: "Key_K",
    76: "Key_L",
    77: "Key_M",
    78: "Key_N",
    79: "Key_O",
    80: "Key_P",
    81: "Key_Q",
    82: "Key_R",
    83: "Key_S",
    84: "Key_T",
    85: "Key_U",
    86: "Key_V",
    87: "Key_W",
    88: "Key_X",
    89: "Key_Y",
    90: "Key_Z",
    136: "Key_NumLock",
    137: "Key_ScrollLock"
}


document.onclick = function (event) {
    if(dowing){
        const target = document.getElementById('img')
        const x = event.offsetX / target.offsetWidth
        const y = event.offsetY / target.offsetHeight
        console.log(dowKey)
        console.log(x,y)
        var km = {
            'comment': dowKey + "",
            'type': "KMT_CLICK",
            'key': kmap[dowKey],
            'pos':{
                'x': x,
                'y': y
            },
            "switchMap": false
        }
        list[dowKey] = km;
        $('.mask').empty()
        var Arrary = []
        for (var key in list) {
            var value = list[key];
            Arrary.push(value)
            $('.mask').append(`
                <button class="button" style="top:${target.offsetHeight*value.pos.y - 16}px;left:${target.offsetWidth * value.pos.x - 16}px;">${value.key}</button>
            `)
        }
        console.log(Arrary)
        Arrary.push({
            "comment": "WHEEL",
            "type": "KMT_STEER_WHEEL",
            "centerPos": {
                "x": 0.16,
                "y": 0.75
            },
            "leftOffset": 0.1,
            "rightOffset": 0.1,
            "upOffset": 0.27,
            "downOffset": 0.2,
            "leftKey": "Key_A",
            "rightKey": "Key_D",
            "upKey": "Key_W",
            "downKey": "Key_S"
        })

        config = {
            "switchKey": "Key_QuoteLeft",
            "mouseMoveMap": {
                "startPos": {
                    "x": 0.57,
                    "y": 0.26
                },
                "speedRatio": 10
            },
            "keyMapNodes": Arrary
        }



        console.log(config)
        $('body').append(`<input type="text" id="copy"></input>`)
        document.getElementById('copy').value = JSON.stringify(config);
        $('#copy').select(); // 选择对象
        document.execCommand("Copy"); // 执行浏览器复制命令
        $('#copy').remove();
    }
}


document.onkeydown = function (event){
    dowing = true
    dowKey = event.keyCode
}

document.onkeyup = function (event){
    dowing = false
}

document.oncontextmenu = function (e) {
    e.preventDefault();
};

document.onmousedown = function (event){
    if (event.button == 0){
        var mouseCode = 'LeftButton'
    }
    else{
        var mouseCode = 'RightButton'
    }
    console.log(mouseCode)
    if (!dowing) {
        const target = document.getElementById('img')
        const x = event.offsetX / target.offsetWidth
        const y = event.offsetY / target.offsetHeight
        console.log(x, y)
        var km = {
            'comment': mouseCode+"",
            'type': "KMT_CLICK",
            'key': mouseCode,
            'pos': {
                'x': x,
                'y': y
            },
            "switchMap": false
        }
        list[mouseCode] = km;

        $('.mask').empty()
        var Arrary = []
        for (var key in list) {
            var value = list[key];
            Arrary.push(value)
            $('.mask').append(`
                <button class="button" style="top:${target.offsetHeight * value.pos.y - 16}px;left:${target.offsetWidth * value.pos.x - 16}px;">${value.key}</button>
            `)
        }

        Arrary.push({
            "comment": "WHEEL",
            "type": "KMT_STEER_WHEEL",
            "centerPos": {
                "x": 0.16,
                "y": 0.75
            },
            "leftOffset": 0.1,
            "rightOffset": 0.1,
            "upOffset": 0.27,
            "downOffset": 0.2,
            "leftKey": "Key_A",
            "rightKey": "Key_D",
            "upKey": "Key_W",
            "downKey": "Key_S"
        })

        config = {
            "switchKey": "Key_QuoteLeft",
            "mouseMoveMap": {
                "startPos": {
                    "x": 0.57,
                    "y": 0.26
                },
                "speedRatio": 10
            },
            "keyMapNodes":Arrary
        }



        console.log(config)
        $('body').append(`<input type="text" id="copy"></input>`)
        document.getElementById('copy').value = JSON.stringify(config);
        $('#copy').select(); // 选择对象
        document.execCommand("Copy"); // 执行浏览器复制命令
        $('#copy').remove();
    }
}