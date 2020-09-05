import json


datas = []

if __name__ == '__main__':
    text = ""
    with open(r"H:\getEventTools\getEventtools\src\out.txt", 'r') as f:
        text = f.read()
    text = [x for x in text.splitlines() if x.startswith("[")][:-1]
    for rec in text:
        data = json.loads(rec)
        if(len(data) == 5):
            datas.append(data)
    with open(r"H:\getEventTools\getEventtools\src\out.js", 'w') as f:
        f.write("data="+json.dumps(datas, indent=4))
