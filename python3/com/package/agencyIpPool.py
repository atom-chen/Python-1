#!/usr/bin/python3

import requests
import threading
import datetime
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
import random
import argparse
import os
import json

ip_Text = "ip.txt"
headers_Text = "headers.txt"

def getHeaders():
    ua = UserAgent(verify_ssl=False)
    headers = {'User-Agent':ua.random}
    return headers

def checkIp(targetUrl,ip):
    headers = getHeaders()
    proxies = {"http": "http://" + ip,"http:": "http://" + ip}
    try:
        response  =requests.get(url = targetUrl,proxies = proxies,headers = headers,timeout = 5).status_code
        if response == 200:
            return [True,headers]
        else:
            return [False,headers]
    except:
        return [False,headers]

#获取代理方法
def findIp(type,pageNum,targetUrl,path,path_headers):
    list = {
        '1': 'http://www.xicidaili.com/nt/', #国内普通代理
        '2': 'http://www.xicidaili.com/nn/',  # 国内高匿代理
        '3': 'http://www.xicidaili.com/wn/',  # 国内https代理
        '4': 'http://www.xicidaili.com/wt/',  # 国外http代理
    }
    url = list[str(type)] + str(pageNum) # 配置url
    headers = getHeaders()
    html = requests.get(url = url,headers = headers,timeout = 5).text
    soup = BeautifulSoup(html,'lxml')
    all = soup.find_all('tr',class_ = 'odd')
    for i in all:
        t = i.find_all('td')
        ip = t[1].text + ':' + t[2].text
        list_ = checkIp(targetUrl,ip)
        is_avail = list_[0]
        header = list_[1]
        if is_avail == True:
            write(path = path,text = ip)
            write(path = path_headers,text = str(header))
            print(ip)
        else:
            print("no:" + ip)

#写入文档
def write(path,text):
    with open(path,'a') as f:
        f.writelines(text)
        f.write('\n')

#清空文档
def truncateFile(path):
    with open(path,'w') as f:
        f.truncate()

#读取文档
def read(path):
    with open(path,'r') as f:
        txt = []
        for s in f.readlines():
            txt.append(s.strip())
    return txt

#计算时间差，=格式：时分秒
def getTimeDiff(start,end):
    seconds = (end - start).seconds
    m,s = divmod(seconds,60)
    h,m =divmod(m,60)
    diff = ("%02d:%02d:%02d" % (h,m,s))
    return diff

def getIp(targetUrl,path,path_headers):
    truncateFile(path)
    start = datetime.datetime.now()
    threads = []
    for type in range(4):
        for pagenum in range(3):
            t = threading.Thread(target = findIp,args = (type + 1,pagenum + 1,targetUrl,path,path_headers))
            threads.append(t)
    print('开始爬取代理IP')
    for s in threads:
        s.start()
    for e in threads:
        e.join()
    print("爬取完成")
    end = datetime.datetime.now()
    diff = getTimeDiff(start,end)
    ips = read(path)
    print(ips)
    print('一共爬取代理IP: %s个,共耗时：%s \n' % (len(ips),diff))

if __name__ == '__main__':
    parser =argparse.ArgumentParser()
    parser.add_argument("-ip","--ipFileName",type = str,default = ip_Text,help = "[[输入ip池文件名]]")
    parser.add_argument("-hd", "--headersFileName", type=str, default=headers_Text, help="[[输入headers池文件名]]")
    parser.add_argument("-url", "--url", type=str, default="", help="[[输入要爬取的网址]]")
    args = parser.parse_args()

    path = args.ipFileName
    path_headers = args.headersFileName
    targetUrl = args.url
    if targetUrl == "":
        print("请输入网址......")
        url = input()
        print(url)
        getIp(url, path, path_headers)
    else:
        getIp(targetUrl,path,path_headers)