#!/usr/bin/python3

import os
import argparse
import shutil
import requests
import sys
import urllib
import urllib3
import re
from bs4 import BeautifulSoup
import configAssets
import json
import xlrd
import xlwt
from xlrd import *
from fake_useragent import UserAgent
import random
import threading,datetime
import ast
import math
import escape
import time
import xlsxwriter
import copy_doc
import copy_doc_class
import agencyIpPoolClass
import JsonToTxt

# "https://www.japanesepod101.com/japanese-vocabulary-lists/?page=2&search=&order=popular"
WORD_URL_1 = configAssets.WORD_URL_1
WORD_URL_2 = configAssets.WORD_URL_2
WORD_URL_3 = configAssets.WORD_URL_3

WORD_URL_JH_1 = configAssets.WORD_URL_JH_1
WORD_URL_JH_2 = configAssets.WORD_URL_JH_2

WORD_URL_K = configAssets.WORD_URL_K
THREAD_Max_NUM = 1000

ALL_JA_WORD = configAssets.ALL_JA_WORD
DOC_JA_NO_DOWN = configAssets.DOC_JA_NO_DOWN
DOC_JA_DOWN = configAssets.DOC_JA_DOWN
DOC_JA_DOWN_PARSE = configAssets.DOC_JA_DOWN_PARSE
ALL_DOWN_JA_WORD = configAssets.ALL_DOWN_JA_WORD

STR_404 = configAssets.STR_404
JS_DATA_FILE = configAssets.JS_DATA_FILE
global JS_RELOAD_LIST
JS_RELOAD_LIST = []

global down_file_name_list
down_file_name_list = []

HIRAGANA = configAssets.HIRAGANA
KATAGANA = configAssets.KATAGANA

Doc_file1 = configAssets.Doc_file1
P_file1 = configAssets.P_file1

Doc_file2 = configAssets.Doc_file2
P_file2 = configAssets.P_file2

Two_UrlDoc = configAssets.Two_UrlDoc
Doc_file3 = configAssets.Doc_file3
URL_DOC_THREE = configAssets.URL_DOC_THREE
URL_FILE_THREE = configAssets.URL_FILE_THREE

urlPageTips_1 = configAssets.urlPageTips_1
urlPageTips_2 = configAssets.urlPageTips_2
All_Url = configAssets.All_Url
URL_DATA_DOC = configAssets.URL_DATA_DOC
URL_DATA_FILE = configAssets.URL_DATA_FILE

URL_DATA_PARSE_DOC_1 = configAssets.URL_DATA_PARSE_DOC_1
URL_DATA_PARSE_FILE_FIX = configAssets.URL_DATA_PARSE_FILE_FIX

Q_JA = "Q_ja"
Q_EN = "Q_en"
A_JA = "A_ja"
A_JA_A = "A_ja_a"
A_EN = "A_en"

Q_1 = "Q1"
Q_2 = "Q2"

IP_TEXT_1 = "ip.txt"
IP_TEXT_INDEX = "ip_index.txt"
f_ip = open(IP_TEXT_1,"r")
IP_Pool = f_ip.readlines()
f_ip.close()

# 得到随机头
HEAD_TEXT_1 = "headers.txt"
f_head = open(HEAD_TEXT_1,"r")
USER_AGENT = f_head.readlines()
f_head.close()

def shell_execute(commond_line):
    return os.system(commond_line)

def getHeaders():
    len_ = len(USER_AGENT)
    index_random = random.randint(0,len_ - 1)
    # agent = USER_AGENT[index_random]
    # headers = {'User-Agent': agent}
    headers = USER_AGENT[index_random]
    return headers

def getRandomIp():
    index_ = 0
    f = open(IP_TEXT_INDEX,"r")
    str_ = f.read()
    f.close()
    str_ = str_.replace("\n","")
    index_ = int(str_)
    index_ = (index_) % len(IP_Pool)
    f = open(IP_TEXT_INDEX,"w")
    f.truncate()
    f.write(str(index_ + 1))
    f.close()
    ip = IP_Pool[index_]
    ip = ip.replace("\n","")
    return ip

def getHtml(url):
    # sleepTime = 1.5 + random.random()
    # print("请求数据: sleep:" + str(sleepTime)
    # time.sleep(sleepTime)
    # ip = getRandomIp()
    headers = getHeaders()
    # proxies = {"http": "http://" + ip,"http": "http://" + ip}
    print(headers)
    html = ""
    try:
        page = requests.get(url = url,headers = headers,timeout = 4)
        print("enter there--->" + page)
        html = page.content.decode("UTF-8")
    except Exception as e:
        pass
    if "window.addEventListener" in html:
        html = ""
    return html

def read(fileName):
    f = open(fileName,"r")
    str_ = f.read()
    f.close()
    return str_

def readLines(fileName):
    f = open(fileName,"r")
    str_ = f.readlines()
    f.close()
    return str_

def write(fileName,str_):
    f = open(fileName)
    str_ = f.write(str_)
    f.close()

def writeListToFile(path,dataList,hasEnter):
    f = open(path,"w")
    for urlStr in dataList:
        f.writelines(urlStr)
        if hasEnter:
            f.write("\n")
    f.close()

def AllUrlOne():
    pageCount = 15
    page = 0
    if not os.path.exists(Doc_file1):
        os.makedirs(Doc_file1)
    while (page <= pageCount):
        fileName = P_file1.replace(".",str(page) + ".")
        url = WORD_URL_1 + str(page) + WORD_URL_2
        page = page + 1
        if os.path.isfile(fileName):
            continue
        print("下载文件" + fileName)
        htmltext = getHtml(url)
        fileContentLen = len(str(htmltext))
        if fileContentLen > 1:
            fp = open(fileName,"w")
            fp.write(htmltext)
            fp.close()
        else:
            continue

def getOpenUrlData(url,fileName):
    print("Url-->>" + url + "--->>>fileName:" + fileName)
    if os.path.isfile(fileName):
        print("已经存在:" + fileName)
        return
    htmltext = getHtml(url)
    print("get html text --->" + htmltext)
    if "<" in str(htmltext):
        print("下载完成")
        fp = open(fileName,"w")
        fp.write(htmltext)
        fp.close()

def parseOneHtml():
    fileList = os.listdir(Doc_file1)
    fileList = sortIndeFile2(fileList,'"page_',".html")
    ##开始写入
    urlList_ = []
    for fileOne in fileList:
        print("fileOnr: " + fileOne)
        pageUrl = parseAOneHtml(Doc_file1 + fileOne)
        urlList_.append(pageUrl)
    writeListToFile(All_Url,urlList_,False)

def parseAOneHtml(fileName):
    if not os.path.isfile(fileName):
        return
    if not os.path.exists(Doc_file2):
        os.makedirs(Doc_file2)
    index = fileName.replace(Doc_file1,"")
    aOneUrls2 = get_url(fileName)
    return aOneUrls2

def get_url(fileName):
    if not os.path.isfile(fileName):
        return
    with open(fileName,'r') as f:
        pattern0 = re.compile(r"<!-- mobile -->[\s\S]*?<!-- desktop grid -->")
        fileData = f.read()
        urlDataList = re.findall(pattern0,fileData)
        content = ""
        cout = 0
        for urlData in urlDataList:
            pattern1 = re.compile(r"<a href=\"[\s\S]*?\"")
            urlArray = re.findall(pattern1,urlData)
            if len(urlArray) > 0 :
                cout += 1
                url = urlArray[0]
                url = url.replace("<a href=\"","")
                url = url.replace("\"","")
                url = WORD_DomainName + url
                content += (url + "\n")
        return content
    return ""

def downAllUrlData():
    if not os.path.isfile(All_Url):
        return
    allUrlFile = open(All_Url,'r')
    urlArray = allUrlFile.readlines()
    if not os.path.exists(Doc_file2):
        os.makedirs(Doc_file2)
    for i in range(0,len(urlArray)):
        url = urlArray[i]
        url = url.replace("\n","")
        fileName = Doc_file2 + URL_DATA_FILE
        fileName = fileName.replace(".","_" + str(i) + ".")
        if os.path.isfile(fileName):
            print("存在:" + str(i))
            continue
        print("不存在:下载:" + fileName)
        print("url: " + url)
        htmltext = getHtml(url)
        fileContentLen = len(str(htmltext))
        if fileContentLen > 1:
            fp = open(fileName,"w")
            fp.write(htmltext)
            fp.close()
        else:
            continue

def threadDown(wordList,_):
    if not os.path.exists(DOC_JA_DOWN):
        os.makedirs(DOC_JA_DOWN)
    # print(wordList)
    for word in wordList:
        parseWord = urllib.parse.quote(word)
        url = WORD_URL_K + parseWord
        fileName = DOC_JA_DOWN + word + ".html"
        getOpenUrlData(url,fileName)

def sortIndeFile2(fileList,fix_1,fix_2):
    indexList_int = []
    for name in fileList:
        pattern = re.compile(r"[0-9]+")
        indexList = re.findall(pattern,name)
        if len(indexList) > 0:
            index = indexList[len(indexList) - 1]
            indexList_int.append(int(index))
    indexList_int = sorted(indexList_int)
    orderList = []
    for i in range(0,len(indexList_int)):
        if i == len(indexList_int):
            continue
        index = indexList_int[i]
        fileName = fix_1 + str(index) + fix_2
        orderList.append(fileName)
    return orderList

#得到文件最后的数字，无则返回 -1
def getFileIndex(fileName):
    pattern = re.compile(r"[0-9]+")
    indexList = re.findall(pattern,fileName)
    index = -1
    if len(indexList) > 0:
        index = str(indexList[len(indexList) - 1])
    return index

#将list 装换成首行缩进的json字符串
def getJsonStr(list):
    jsonStr = json.dumps(list,encoding="UTF-8",ensure_ascii=False,indent=2)
    return jsonStr

def getJson(json_path):
    file = open(json_path)
    config = json.load(file)
    return config

def getJsonData(json_str):
    config = json.loads(json_str)
    return config

def parseUrlData():
    if not os.path.exists(DOC_JA_DOWN):
        return
    if not os.path.exists(DOC_JA_DOWN_PARSE):
        os.makedirs(DOC_JA_DOWN_PARSE)
    urlFileArray = os.listdir(DOC_JA_DOWN)
    count = 0
    for urlFileName in urlFileArray:
        if "html" not in urlFileName:
            continue
        urlFileN = DOC_JA_DOWN + urlFileName
        parseName = DOC_JA_DOWN_PARSE + urlFileName
        parseAUrlData(urlFileN)

def parseAUrlData(urlFile,parseName):
    parseData = {
        Q_1:[],
        Q_2:[],
    }
    f = read(urlFile)
    word = urlFile.replace(DOC_JA_DOWN,"")
    word = word.replace(".html","")
    global JS_RELOAD_LIST
    if "window.addEventListener" in f:
        print(word)
        JS_RELOAD_LIST.append(word)
        os.remove(urlFile)
        return
    print("----->>>>>11111111")
    if "<h1 class=\"display-1\">四〇四 <small class=\"text-muted\">404</small></h1>" in f:
        down_file_name_list.append(word + "|" + STR_404)
        return
    print("---->>>22222222")
    pattern_1 = re.compile(r"<li class=\"list-group-item\"><div></div>[\s\S]+?<span")
    Q_1_List = re.findall(pattern_1,f)
    if len(Q_1_List[0])>= 1:
        q_1 = Q_1_List[0]
        q_1 = q_1.replace("<li class=\"list-group-item\"><div></div>\n              ", "")
        q_1 = q_1.replace(" <span","")
        down_file_name_list.append(word + "|" + q_1)

###判断单个德语单词是否合法
def legalDeWord(word_de):
    if len(word_de) >= 3 and len(word_de) <= 9:
        return True
    return False

def legalDeWord_A(word_de):
    word = ""
    if "。" in word_de:
        word_de = word_de.replace("。","")
    if "！" in word_de:
        word_de = word_de.replace("！",";")
    if legalDeWord(word_de):
        word = word_de
    return word

def deleFristEndSpace(word):
    if spaceStr(word) == "":
        return ""
    while word[0] == " ":
        if spaceStr(word) == "":
            return ""
        word = word[1:]
    if spaceStr(word) == "":
        return ""
    while word[len(word) - 1] == " ":
        if spaceStr(word) == "":
            return ""
        word = word[:-1]
    return word

def spaceStr(word):
    if word == " " or len(word) == 0:
        return ""
    return word

def filtrateData(jsonData): # 判断某个json(即该关卡)是否合法
    q_de = jsonData[Q_JA]
    q_en = jsonData[Q_EN]
    a_de_list = jsonData[A_JA] # getJsonData(getJsonStr(jsonData[A_DE])) # jsonData[A_DE]
    a_en_list = jsonData[A_EN] # getJsonData(getJsonStr(jsonData[A_EN]))
    a_de_a_list = jsonData[A_JA_A]
    legalIndexList = []
    for i in range(0, len(a_de_a_list)):
        word_de = legalDeWord_A(a_de_a_list[i])
        if word_de != "":
            legalIndexList.append(i)
    # print "getJsonStr(legalIndexList):\n"+ getJsonStr(legalIndexList)
    a_de = ""
    a_de_a = ""
    a_en = ""
    i_ = 0
    if len(legalIndexList) == 0:
        return False
    while i_ < len(legalIndexList):
        i_legal = legalIndexList[i_]
        # a_de.append(a_de_list[i_legal])
        # a_en.append(a_en_list[i_legal])
        try:
            a__ = a_de_list[i_legal]
            a__ = a__.replace("。", "")
            a__ = a__.replace("！", "")
            a_de += a__ + ";"
        except Exception as e:
            pass
        try:
            a__ = a_de_a_list[i_legal]
            a__ = a__.replace("。", "")
            a__ = a__.replace("！", "")
            a_de_a += a__ + ";"
        except Exception as e:
            pass
        try:
            a_en += a_en_list[i_legal] + ";"
        except Exception as e:
            pass
        i_ += 1
    a_de = a_de[:-1]
    a_de_a = a_de_a[:-1]
    a_en = a_en[:-1]
    data = {
        Q_JA: q_de,
        Q_EN: q_en,
        A_JA: a_de,
        A_JA_A: a_de_a,
        A_EN: a_en,
    }
    return data

def mergeAllUrlJsonData():
    if not os.path.exists(URL_DATA_PARSE_DOC_1):
        return
    urlDataJsonList = os.listdir(URL_DATA_PARSE_DOC_1)
    urlDataJsonList = sortIndeFile2(urlDataJsonList, "parseFile_", ".json")
    dataList = []
    index = 0
    for jsonFile in urlDataJsonList:
        jsonFile = URL_DATA_PARSE_DOC_1 + jsonFile
        print("-->jsonFile:"+jsonFile)
        jsonData = getJson(jsonFile)
        # print("getJsonStr(jsonData):\n"+getJsonStr(jsonData))
        # jsonData = getJsonData(getJsonStr(jsonData))
        q_en = jsonData[Q_EN]
        q_ja = jsonData[Q_JA]
        a_en = jsonData[A_EN]
        a_ja = jsonData[A_JA]
        a_ja_a = jsonData[A_JA_A]
        # print("-->getJsonStr:\n"+str(getJsonData(getJsonStr(a_de))[10]))
        # print("-->getJsonStr:\n"+str(getJsonData(getJsonStr(a_de))[10]))
        legalData = filtrateData(jsonData)
        if legalData:
            dataList.append(legalData)
            print("合法:" + str(index) + ":")
            # print(getJsonStr(legalData))
        else:
            print("不合法:" + str(index))
        index += 1
    wbk = xlwt.Workbook() #创建一个工作簿
    ws = wbk.add_sheet('swipe') #创建一个工作表
    ws.write(0, 0, "Q(JA)")
    ws.write(0, 1, "Q(En)")
    ws.write(0, 2, "A(JA)")
    ws.write(0, 3, "A(JA_A)")
    ws.write(0, 4, "A(En)")
    for i in range(0, len(dataList)):
        q__ja = dataList[i][Q_JA]
        q__en = dataList[i][Q_EN]
        a__ja = dataList[i][A_JA]
        a__ja_a = dataList[i][A_JA_A]
        a__en = dataList[i][A_EN]
        ws.write(i + 1, 0, q__ja)
        ws.write(i + 1, 1, q__en)
        ws.write(i + 1, 2, a__ja)
        ws.write(i + 1, 3, a__ja_a)
        ws.write(i + 1, 4, a__en)
    wbk.save('swipe_ja.xls')

def getFormatNumberString(n,num): # n:位数 num:要格式化的数 [n=3 num=4 -> 004]
    str_ = str(num)
    if len(str_) >= n:
        return str(num)
    zero = ""
    addN = n - len(str_)
    for _ in range(0,addN):
        zero += "0"
    str_ = zero + str_
    return str_

def getWordOfList(list_,c): # 根据一个单词list,生成一个以c分隔的字符串
    w_ = ""
    for i in range(0,len(list_)):
        if i == 0:
            w_ = w_ + list_[i]
        else:
            w_ = w_ + c + list_[i]
    return w_

# 获取到词频小于10的词
def parseAllJapanWord():
    wordList = readLines("word_japan.csv")
    wordList_j = []
    print(len(wordList))

    for i in range(1,len(wordList)):
        wordConfig = wordList[i]
        wordConfig = wordConfig.split(",")
        if int(wordConfig[1]) <= 10:
            continue
        wordList_j.append(wordConfig[2])
    writeListToFile(ALL_JA_WORD,wordList_j,True)

def getJapanCharList(word_ja):
    len_ = len(word_ja)
    num = math.floor(len_ / 3)
    jaList = []
    for i in range(0,num):
        char = word_ja[(i)*3:(i+1)*3]
        jaList.append(char)
    return jaList

def isNeedDown(word_ja):
    charList = getJapanCharList(word_ja)
    needDown = False
    for char in charList:
        if char not in HIRAGANA and char not in KATAGANA:
            needDown = True
            break
    return needDown

def parseNoDown():
    if not os.path.exists(DOC_JA_NO_DOWN):
        os.makedirs(DOC_JA_NO_DOWN)
    if not os.path.exists(DOC_JA_DOWN):
        os.makedirs(DOC_JA_DOWN)
    downList = []
    nodownList = []
    allWordList = readLines(ALL_JA_WORD)
    print(allWordList)
    for word in allWordList:
        word = word.replace("\n","")
        if isNeedDown(word):
            fileName = DOC_JA_DOWN + word + ".html"
        else:
            fileName = DOC_JA_NO_DOWN + word + ".html"
            nodownList.append(word + "|" + word)
            pass
    writeListToFile("down_noDown_file_name.html",nodownList,True)

def downJaData():
    downWordList = readLines(ALL_DOWN_JA_WORD)
    # print(downWordList)
    allWordNum = len(downWordList)
    allList = []
    aList = []
    start = datetime.datetime.now()
    print("--->allWordNum:" + str(allWordNum))
    for i in range(0,allWordNum):
        downWord = downWordList[i]
        downWord = downWord.replace("\n","")
        aList.append(downWord)
        if len(aList) == THREAD_Max_NUM or i == allWordNum -1:
            allList.append(aList)
            aList = []
        threads = []
        for aList in allList:
            t = threading.Thread(target=threadDown,args=(aList,"_"))
            threads.append(t)
        for s in threads:
            s.start()
        for e in threads:
            e.join()
    # print(allList)
    end = datetime.datetime.now()
    diff = getTimeDiff(start, end)
    print('共耗时：%s \n' % (diff))

#计算时间差，=格式：时分秒
def getTimeDiff(start,end):
    seconds = (end - start).seconds
    m,s = divmod(seconds,60)
    h,m =divmod(m,60)
    diff = ("%02d:%02d:%02d" % (h,m,s))
    return diff

def checkWord(Doc,file1,file2):
    allWordList = readLines(file1)
    list_ = []
    for word in allWordList:
        word = word.replace("\n","")
        fp = Doc + word + ".html"
        if not os.path.isfile(fp):
            print(fp)
            list_.append(word)
    # writeListToFile(file2,list_,True)

def mytest():
    wordlist = readLines(ALL_DOWN_JA_WORD)
    downlist_ = os.listdir(DOC_JA_DOWN)
    filterList = []
    for word in wordlist:
        if word not in filterList:
            filterList.append(word)
    print(len(filterList))

def writeExcel():
    downData = readLines("down_nodown_file_name.html")
    downJson = {}
    downJson["default"] = ""
    for i in range(0,len(downData)):
        lineStr = downData[i]
        lineStr = lineStr.replace("\n","")
        lineStr = lineStr.split("|")
        key = lineStr[0]
        value = lineStr[1]
        downJson[key] = value
        print(key)
        print(downJson[key])

    excel_1 = "word_japan.csv"
    csvData = readLines(excel_1)
    jsonDataList_ = []
    for i in range(1, len(csvData)):
        lineStr__ = csvData[i].replace("\n", "")
        jsonData_ = lineStr__.split(",")
        jsonDataList_.append(jsonData_)
        print("--------------------------------------------lineStr__:" +
              jsonData_[0] + ":" + jsonData_[1] + ":" + jsonData_[2] + ":" + jsonData_[3])
        print("行: " + str(i))
        word = jsonData_[2]
        word_tras = ""
        try:
            word_tras = downJson[word]
            # print("--->>word_tras:"+word_tras)
        except Exception  as e:
            word_tras = ""
        # if word_tras != "":
        #     print("-------------------------------word_tras:" + word_tras)
        print("--" + jsonData_[3] + "--")
        jsonData_[3] = word_tras
        # print("-------------------------------word_tras:" + word_tras)

        # # 2. 创建新表
        # excel_2 = xlwt.Workbook(encoding='utf-8')
    excel_2 = xlsxwriter.Workbook('ja.xlsx')
    # sheet_2 = excel_2.add_sheet("word_japan")
    sheet_2 = excel_2.add_worksheet(u'word_japan')
    sheet_2.write(0, 0, "index")
    sheet_2.write(0, 1, "freq")
    sheet_2.write(0, 2, "word")
    sheet_2.write(0, 3, "pronunciation")
    for i in range(0, len(jsonDataList_)):
        jsonData_ = jsonDataList_[i]
        print("excel:" + str(i))
        sheet_2.write(i + 1, 0, jsonData_[0])
        sheet_2.write(i + 1, 1, jsonData_[1])
        sheet_2.write(i + 1, 2, jsonData_[2])
        sheet_2.write(i + 1, 3, jsonData_[3])
    # excel_2.save("ja.xls")
    excel_2.close()

if __name__ == '__main__':
    work_space_path = os.getcwd()
    print("work_space_path: " + work_space_path)

    fCopy = copy_doc_class.copy_doc_class()
    fIpPool = agencyIpPoolClass.agencyIpPoolClass()
    fJTT = JsonToTxt.JsonToTxt()
    # 新代码
    # parseAllJapanWord()
    # parseNoDown()
    # downJaData()  # 下载allUrlData
    # parseUrlData()
    # writeListToFile(JS_DATA_FILE, JS_RELOAD_LIST, True)
    # writeListToFile("down_file_name.html", down_file_name_list, True)

    # 解析到excle
    # writeExcel()
    print('          [1]:解析所有文字(parseAllJapanWord)')
    print('          [2]:解析没有下载(parseNoDown)')
    print('          [3]:下载数据(downJaData)')
    print('          [4]:解析URL中的数据(parseUrlData)')
    print('          [5]:将文件写入js_reload.html中(writeListToFile)')
    print('          [6]:将文件写入down_file_name.html中(writeListToFile)')
    print('          [7]:解析到excle(writeExcel)')
    print('          [8]:拷贝文件操作(copy_doc)')
    print('          [9]:爬取代理IP(agencyIpPoolClass)')
    print('          [10]:获取文件夹(JsonToTxt)')
    selectIndex = input('选择操作,输入数字编号: ')
    print("输入编号--->: ", selectIndex)
    if selectIndex == '1':
        parseAllJapanWord()
    elif selectIndex == '2':
        parseNoDown()
    elif selectIndex == '3':
        downJaData()
    elif selectIndex == '4':
        parseUrlData()
    elif selectIndex == '5':
        writeListToFile(JS_DATA_FILE, JS_RELOAD_LIST, True)
    elif selectIndex == '6':
        writeListToFile("down_file_name.html", down_file_name_list, True)
    elif selectIndex == '7':
        writeExcel()
    elif selectIndex == '8':
        fCopy.runCopy()
    elif selectIndex == '9':
        fIpPool.getIpHeadersByNetWork()
    elif selectIndex == '10':
        fJTT.getContent()
    else:
        print("编号输入错误!")
        try:
            sys.exit(0)
        except:
            print("退出进程")
        finally:
            print("cleanup")