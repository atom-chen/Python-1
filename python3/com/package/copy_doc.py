#!/usr/bin/python3

import os
import argparse
import shutil

def copy_a_doc_file(fileP,targetP):
    if not os.path.isdir(fileP):
        return
    if os.path.isdir(targetP):
        if REPLACE_ALL_RES == "y":
            del_file(targetP)
    else:
        os.makedirs(targetP)
    list_ = list_all_files(fileP)
    for fileP_ in list_:
        file = fileP_.replace(fileP,"")
        targetP_ = targetP + file
        f_ = targetP_.split("/")[-1]
        target_doc = targetP_.replace(f_,"")
        if not os.path.exists(target_doc):
            os.makedirs(target_doc)

        shutil.copyfile(fileP_,targetP_)

def del_file(path):
    for i in os.listdir(path):
        path_file = os.path.join(path.i)
        if os.path.isfile(path_file):
            os.remove(path_file)
        else:
            del_file(path_file)

def list_all_files(rootdir):
    _files = []
    list_ = os.listdir(rootdir)  # 列出文件夹下所有的目录与文件
    for i in range(0, len(list_)):
        path = os.path.join(rootdir, list_[i])
        if os.path.isdir(path):
            _files.extend(list_all_files(path))
        if os.path.isfile(path):
            _files.append(path)
    return _files

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.description = "拷贝文件"
    parser.add_argument("-fp", "--FilePath", type=str, default="", help="[[ 输入文件路径 ]]")
    parser.add_argument("-tp", "--TargetPath", type=str, default="", help="[[ 输入目标路径 ]]")
    parser.add_argument("-isReplace", "--ReplaceAllRes", type=str, default="n", help="[[ 是否替换之前的target路径下的资源 ]]")

    # parser.add_argument("echo")
    args = parser.parse_args()


    FILE_PATH = args.FilePath
    TARGET_PATH = args.TargetPath
    REPLACE_ALL_RES = args.ReplaceAllRes
    print("-->FILE_PATH:" + FILE_PATH)
    print("-->TARGET_PATH:" + TARGET_PATH)
    copy_a_doc_file(FILE_PATH, TARGET_PATH)

