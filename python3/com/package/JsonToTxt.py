#!/usr/bin/python3

import os
import sys
import json
import datetime
import csv
# import numpy as np
# import pandas as pd
# import copy_doc_class

SOURCE_FILE1 = "/Users/s/Documents/Crwaler/wordMocha/data/levels"
TARGET_FILE_DIR1 = "/Users/s/Documents/Crwaler/wordMocha/target"
TARGET_FILE1 = "/Users/s/Documents/Crwaler/target/targetMocha.txt"
TARGET_CSV1 = "/Users/s/Documents/Crwaler/target/targetMocha.csv"

SOURCE_FILE2 = "/Users/s/Documents/Crwaler/wordStacks/data/levels"
TARGET_FILE_DIR2 = "/Users/s/Documents/Crwaler/wordStacks/target"
TARGET_FILE2 = "/Users/s/Documents/Crwaler/target/targetStacks.txt"
TARGET_CSV2 = "/Users/s/Documents/Crwaler/target/targetStacks.csv"

SOURCE_FILE3 = "/Users/s/Documents/Crwaler/wordBloom/data/levels"
TARGET_FILE_DIR3 = "/Users/s/Documents/Crwaler/wordBloom/target"
TARGET_FILE3= "/Users/s/Documents/Crwaler/target/targetBloom.txt"
TARGET_CSV3 = "/Users/s/Documents/Crwaler/target/targetBloom.csv"

SOURCE_FILE4 = "/Users/s/Documents/Crwaler/wordUncrossed/data/levels"
TARGET_FILE_DIR4 = "/Users/s/Documents/Crwaler/wordUncrossed/target"
TARGET_FILE4 = "/Users/s/Documents/Crwaler/target/targetUncrossed.txt"
TARGET_CSV4 = "/Users/s/Documents/Crwaler/target/targetUncrossed.csv"

SOURCE_FILE5 = "/Users/s/Documents/Crwaler/word_v/data/levels"
TARGET_FILE_DIR5 = "/Users/s/Documents/Crwaler/word_v/target"
TARGET_FILE5 = "/Users/s/Documents/Crwaler/target/target_v.txt"
TARGET_CSV5 = "/Users/s/Documents/Crwaler/target/target_v.csv"

TARGET_FILE = "/Users/s/Documents/Crwaler/target/target.txt"
SOURCE_FILE = "/Users/s/Documents/Crwaler/target"
TARGET_CSV = "/Users/s/Documents/Crwaler/target/target.csv"

TARGET_FILE6 = "/Users/s/Documents/Crwaler/target/DelDuplicateData.txt"
TARGET_CSV6 = "/Users/s/Documents/Crwaler/target/DelDuplicateData.csv"

ALL_SOURCE_FILE = "/Users/s/Documents/Crwaler/word"
ALL_TARGET_FILE = "/Users/s/Documents/Crwaler/word/target.txt"

class JsonToTxt:

    # 计算时间差，=格式：时分秒
    def getTimeDiff(self,start, end):
        seconds = (end - start).seconds
        m, s = divmod(seconds, 60)
        h, m = divmod(m, 60)
        diff = ("%02d:%02d:%02d" % (h, m, s))
        return diff

    def write(self,fileName, str_):
        with open(fileName, 'a') as f:
            f.writelines(str_)
            f.write('\n')

    # 清空文档
    def truncateFile(self,path):
        with open(path, 'w') as f:
            f.truncate()

    # 读取文档
    def read(self,path):
        with open(path, 'r') as f:
            txt = []
            for s in f.readlines():
                txt.append(s.strip())
        return txt

    def getContent1(self):
        self.truncateFile(TARGET_FILE1)
        dirs = os.listdir(SOURCE_FILE1)
        for file in dirs:
            print(file)
            if os.path.isfile(os.path.join(SOURCE_FILE1, file)):
                f = open(os.path.join(SOURCE_FILE1, file), 'r+')
                str_json = f.read()
                # print(str_json)
                temp = json.loads(str_json)
                # print(temp)
                # ##1,2通用
                for fc in temp:
                    str_value = temp[fc]
                    # print(fc)
                    print(str_value)
                    # print(str_value['d'])
                    str_list = str_value['d']
                    for i_str in str_list:
                        len_index = i_str.find(",")
                        if len_index != -1:
                            i_str = i_str[:len_index]
                        print(i_str)
                        self.write(TARGET_FILE1, str(i_str))

    def getContent2(self):
        self.truncateFile(TARGET_FILE2)
        dirs = os.listdir(SOURCE_FILE2)
        for file in dirs:
            print(file)
            if os.path.isfile(os.path.join(SOURCE_FILE2, file)):
                f = open(os.path.join(SOURCE_FILE2, file), 'r+')
                str_json = f.read()
                # print(str_json)
                temp = json.loads(str_json)
                # print(temp)
                # ##1,2通用
                for fc in temp:
                    str_value = temp[fc]
                    # print(fc)
                    print(str_value)
                    # print(str_value['e'])
                    str_list = str_value['e']
                    for i_str in str_list:
                        # print(i_str)
                        self.write(TARGET_FILE2, str(i_str))

    def getContent3(self):
        self.truncateFile(TARGET_FILE3)
        dirs = os.listdir(SOURCE_FILE3)
        for file in dirs:
            print(file)
            if os.path.isfile(os.path.join(SOURCE_FILE3, file)):
                f = open(os.path.join(SOURCE_FILE3, file), 'r+')
                str_json = f.read()
                # print(str_json)
                temp = json.loads(str_json)
                # print(temp)
                #### 3单独算法
                for fc in temp:
                    str_value = temp[fc]
                    # print(fc)
                    print(str_value)
                    # print(str_value['f'])
                    str_list = str_value['f']
                    for i_str in str_list:
                        print(i_str)
                        len_index = i_str.rfind(",")
                        i_str = i_str[len_index + 1:]
                        print(i_str)
                        self.write(TARGET_FILE3, str(i_str))

    def getContent4(self):
        self.truncateFile(TARGET_FILE4)
        dirs = os.listdir(SOURCE_FILE4)
        for file in dirs:
            print(file)
            if os.path.isfile(os.path.join(SOURCE_FILE4, file)):
                f = open(os.path.join(SOURCE_FILE4, file), 'r+')
                str_json = f.read()
                # print(str_json)
                temp = json.loads(str_json)
                # print(temp)
                #### 4单独算法
                for fc in temp:
                    str_value = temp[fc]
                    # print(fc)
                    # print(str_value)
                    print(str_value['e'])
                    str_list = str_value['e']
                    for i_str in str_list:
                        len_index = i_str.rfind(",")
                        i_str = i_str[len_index + 1:]
                        print(i_str)
                        self.write(TARGET_FILE4, str(i_str))

    def getContent5(self):
        self.truncateFile(TARGET_FILE5)
        dirs = os.listdir(SOURCE_FILE5)
        for file in dirs:
            # print(file)
            if os.path.isfile(os.path.join(SOURCE_FILE5, file)):
                print(os.path.join(SOURCE_FILE5, file))
                f = open(os.path.join(SOURCE_FILE5, file), 'r+')
                str_json = f.read()
                # print(str_json)
                temp = json.loads(str_json)
                # print(temp)
                ##5单独算法，两种格式都存在
                for fc in temp:
                    str_value = temp[fc]
                    str_list = str_value['e']
                    for i_str in str_list:
                        # print(i_str)
                        if "," in i_str:
                            len_index = i_str.rfind(",")
                            i_str = i_str[len_index + 1:]
                        self.write(TARGET_FILE5, str(i_str))

    def getContent6(self):
        self.truncateFile(TARGET_FILE)
        dirs = os.listdir(SOURCE_FILE)
        start = datetime.datetime.now()
        for file in dirs:
            print(file)
            start1 = datetime.datetime.now()
            if file == ".DS_Store" or file == "target.txt" or file == "DelDuplicateData.txt" or ".csv" in file :
                print("不用读取数据")
            else:
                print('文件名：-->%s \n' % (file))
                if os.path.isfile(os.path.join(SOURCE_FILE, file)):
                    f = self.read(os.path.join(SOURCE_FILE, file))
                    for str_f in f:
                        self.write(TARGET_FILE, str(str_f))
            end1 = datetime.datetime.now()
            diff1 = self.getTimeDiff(start1, end1)
            print('文件:%s -- 共耗时：-->%s \n' % (file,diff1))
        end = datetime.datetime.now()
        diff = self.getTimeDiff(start, end)
        print('合并所有文件共耗时：-->%s \n' % (diff))


    ###去重
    def removeDuplicatedData(self):
        self.truncateFile(TARGET_FILE6)
        newtxtlist = [""]
        start = datetime.datetime.now()
        txtList = self.read(TARGET_FILE)
        # print(txtList)
        for str_txt in txtList:
            if not str_txt in newtxtlist:
                newtxtlist.append(str_txt)

        print(newtxtlist)
        print(len(txtList))
        for i_str in newtxtlist:
            self.write(TARGET_FILE6, str(i_str))
        end = datetime.datetime.now()
        diff = self.getTimeDiff(start, end)
        print('文件:%s -- 共耗时：-->%s \n' % (len(newtxtlist),diff))

    ###将数据写入csv文件中
    def writeToCsv(self):
        # cpath = os.path.join(SOURCE_FILE, "DelDuplicateData.csv")
        # cpath = TARGET_CSV
        # with open(cpath, 'w', newline='') as csvfile:
        #     writer = csv.writer(csvfile)
        #     data = open(TARGET_FILE)
        #     print(data)
        #     for each_line in data:
        #         print(each_line)
        #         if "\n" in each_line:
        #             print("test===>>>>>>>")
        #             each_line = each_line.replace("\n", "")
        #         print(each_line)
        #         writer.writerow([each_line])
        dirs = os.listdir(SOURCE_FILE)
        start = datetime.datetime.now()
        for file in dirs:
            print(file)
            start1 = datetime.datetime.now()
            if file == ".DS_Store" or ".csv" in file:
                print("不用读取数据")
            else:
                fileCsv = file
                fileCsv = fileCsv.replace(".txt", "")
                fileCsv = fileCsv + ".csv"
                filePath = os.path.join(SOURCE_FILE, file)
                print('文件名：-->%s   csv文件-->>>%s\n' % (file,fileCsv))
                cpath = os.path.join(SOURCE_FILE, fileCsv)
                with open(cpath, 'w', newline='') as csvfile:
                    writer = csv.writer(csvfile)
                    data = open(filePath)
                    print(data)
                    for each_line in data:
                        if "\n" in each_line:
                            # print("test===>>>>>>>")
                            each_line = each_line.replace("\n", "")
                        writer.writerow([each_line])

            end1 = datetime.datetime.now()
            diff1 = self.getTimeDiff(start1, end1)
            print('文件:%s -- 共耗时：-->%s \n' % (file, diff1))
        end = datetime.datetime.now()
        diff = self.getTimeDiff(start, end)
        print('合并所有文件共耗时：-->%s \n' % (diff))

    def getContent(self):
        self.stext = ""
        print('          [1]:获取数据Mocha')
        print('          [2]:获取数据Stacks')
        print('          [3]:获取数据Bloom')
        print('          [4]:获取数据Uncrossed')
        print('          [5]:获取数据Scapes')
        print('          [6]:合并文件数据')
        print('          [7]:对合并文件数据去重')
        print('          [8]:将文件写入csv')
        selectIndex = input('选择操作,输入数字编号: ')
        print("输入编号--->: ", selectIndex)
        if selectIndex == '1':
            self.getContent1()
        elif selectIndex == '2':
            self.getContent2()
        elif selectIndex == '3':
            self.getContent3()
        elif selectIndex == '4':
            self.getContent4()
        elif selectIndex == '5':
            self.getContent5()
        elif selectIndex == '6':
            self.getContent6()
        elif selectIndex == '7':
            self.removeDuplicatedData()
        elif selectIndex == '8':
            self.writeToCsv()
        else:
            print("编号输入错误!")
            try:
                sys.exit(0)
            except:
                print("退出进程")
            finally:
                print("cleanup")
