# -*- coding: utf-8 -*-

import os
import os.path
import hashlib
import datetime

root_path = "../client/"
res_path = "res"
src_path = "src"
hash_file = "../client/res/hashfile.lua"
config_path = "config.json"
sep = "/"

png_md5_list = {}


def _genhashfiles(hashfile):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    fp = open(hashfile, 'w')
    fp.truncate()
    fp.write("--------------------------------------------------\n")
    fp.write("--info: hash table\n")
    fp.write("--author: v\n")
    fp.write("--date: " + now + "\n")
    fp.write("--------------------------------------------------\n\n")
    fp.write("hashtable = {\n")
    md5_path_list = [res_path, src_path]
    for xxx in xrange(len(md5_path_list)):
        md5_path = root_path + md5_path_list[xxx]
        for parent, dirnames, filenames in os.walk(md5_path):
            for filename in filenames:
                if filename.startswith("."):
                    continue
                if filename == config_path:
                    continue
                if os.path.isdir(parent + sep + filename):
                    continue
                elif os.path.isfile(parent + sep + filename):
                    len(parent)
                    path_parent = parent.replace("\\", "/")
                    pathname = path_parent + sep + filename
                    writefilepath = pathname[len(root_path): len(pathname)]
                    md5 = _hash_md5(path_parent + sep + filename)
                    filesize = os.path.getsize(path_parent + sep + filename)
                    fp.write(
                        "[\"" + writefilepath + "\"]" + "=" + "{md5=" + "\"" + md5 + "\"" + ",fileSize=" + "\"" + str(
                            filesize) + "\"" + "}" + ",\n")
                else:
                    continue
    configmd5 = _hash_md5(root_path + config_path)
    configsize = os.path.getsize(root_path + config_path)
    fp.write("[\"" + config_path + "\"]" + "=" + "{md5=" + "\"" + configmd5 + "\"" +
             ",fileSize=" + "\"" + str(configsize) + "\"" + "}" + ",\n")
    fp.write("}\n")
    fp.flush()
    fp.close()


def _hash_md5(filename):
    md5 = hashlib.md5()
    fp = open(filename, 'rb')
    md5.update(fp.read())
    fp.close()
    return md5.hexdigest()


def generate():
    _genhashfiles(hash_file)
