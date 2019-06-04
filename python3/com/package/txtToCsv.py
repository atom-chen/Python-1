#!/usr/bin/python3

##description:将.txt数据转换为 .csv文件

import os
import sys
import json
import datetime
import csv

SOURCE_FILE_TXT = "/Users/s/Documents/rollout.txt"
SOURCE_FILE_TXT1 = "/Users/s/Documents/rollout1.txt"
TARGET_FILE_CSV = "/Users/s/Documents/rollout.csv"

class txtToCsv:
    #获取时间差
    def getTimeDiff(self,start,end):
        seconds = (end - start).seconds
        m,s = divmod(seconds,60)
        h,m = divmod(m,60)
        diff = ("%02d:%02d:%02d" % (h,m,s))
        return diff

    def write(self, fileName, str_):
        with open(fileName, 'a') as f:
            f.writelines(str_)
            f.write('\n')

    # 清空文档
    def truncateFile(self, path):
        with open(path, 'w') as f:
            f.truncate()

    # 读取文档
    def read(self, path):
        with open(path, 'r') as f:
            txt = []
            for s in f.readlines():
                txt.append(s.strip())
        return txt

    def getContent(self):
        start = datetime.datetime.now()
        f = open(SOURCE_FILE_TXT,'r+')
        str_json = f.read()
        # print(str_json)
        self.truncateFile(SOURCE_FILE_TXT1)
        tempStr = json.loads(str_json)
        # print(tempStr)
        print("************文件数量**************")
        length = len(tempStr)
        print(length)
        print("*********************************")
        with open(TARGET_FILE_CSV,'w',newline='') as csvFile:
            writer = csv.writer(csvFile)

            for i_str in tempStr:
                # print(i_str)
                i_str = i_str.replace("\n", "")
                self.write(SOURCE_FILE_TXT1, i_str)
                writer.writerow([i_str])

        end = datetime.datetime.now()
        diff = self.getTimeDiff(start, end)
        print('共耗时：-->%s---start-->%s--end-->>>%s \n' % (diff,start,end))


if __name__ == '__main__':
    txtTocsv = txtToCsv()
    txtTocsv.getContent()