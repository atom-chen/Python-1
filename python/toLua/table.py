#!/usr/bin/python
# -*- coding: utf-8 -*-

import codecs
import json
import os
import re
import shutil

import sys
import xlrd

import log

yes = "y"
no = "n"

TABLE_ROOT_DIR = "/table/"
SERVER_TABLE_OUT_DIR = "../server/table/"
CLIENT_TABLE_OUT_DIR = "../client/table/"

SERVER_TABLE_LIST = {
    "cardType_config": "id"
}

CLENT_TABLE_LIST = {
    "cardType_config": "id"
}

PARSE_TYPE_BOOL = u"布尔"
PARSE_TYPE_INT = u"整数"
PARSE_TYPE_FLOAT = u"小数"
PARSE_TYPE_STR = u"文本"
PARSE_TYPE_INT_ARRAY = u"整数数组"
PARSE_TYPE_FLOAT_ARRAY = u"小数数组"
PARSE_TYPE_STR_ARRAY = u"文本数组"
PARSE_TYPE_JSON = u"JSON"


def normalize(original):
    return original.replace(u"，", u",")


def fixjson(origin):
    origin = origin.strip()
    if origin.startswith('['):
        pass
    elif not origin.startswith('{'):
        origin = "{" + origin + "}"
    regexp = re.compile(r"([0-9A-Za-z_-]+)(?=:)")
    subed = regexp.sub('"\\1"', origin)
    # regexp = re.compile(r'(?<=[,\[])([\.0-9A-Za-z_-]+)(?=[,\]])')
    # subed = regexp.sub('"\\1"', subed)
    return subed


def unicode2str(input_str):
    if isinstance(input_str, dict):
        return {unicode2str(key): unicode2str(value) for key, value in input_str.iteritems()}
    elif isinstance(input_str, list):
        return [unicode2str(element) for element in input_str]
    elif isinstance(input_str, unicode):
        return input_str.encode('utf-8')
    else:
        return input_str


def parse_xls(filename, sheet, index_key, results):
    book = xlrd.open_workbook(filename)
    sh = book.sheet_by_index(sheet)
    for rx in range(3, sh.nrows):
        val_type = sh.cell_type(rowx=rx, colx=0)
        if val_type == xlrd.XL_CELL_EMPTY:
            continue
        item = dict()
        for cx in range(0, sh.ncols):
            key = sh.cell_value(rowx=1, colx=cx).encode('utf-8')
            _type = unicode(sh.cell_value(rowx=2, colx=cx))
            parse_cell(item, sh, key, rx, cx, _type, filename)
        try:
            results[item[index_key]] = item
        except Exception, e:
            log.error("Parse file:%s, error" % filename)
            raise e


def parse_cell(target, sh, key, row, col, _type, filename):
    val = sh.cell_value(rowx=row, colx=col)
    val_type = sh.cell_type(rowx=row, colx=col)
    try:
        if val_type == xlrd.XL_CELL_TEXT:
            val = val
        if not (val_type in (xlrd.XL_CELL_TEXT, xlrd.XL_CELL_EMPTY)):
            if _type == PARSE_TYPE_FLOAT or _type == PARSE_TYPE_FLOAT_ARRAY:
                val = str(float(val))
            else:
                val = str(int(val))
        if _type == PARSE_TYPE_BOOL:
            if str(val) == "FALSE" or str(val) == "false" or str(val) == "0":
                target[key] = False
            else:
                target[key] = True
        elif _type == PARSE_TYPE_INT:
            if val == "":
                target[key] = 0
            else:
                target[key] = int(val)
        elif _type == PARSE_TYPE_FLOAT:
            if val == "":
                target[key] = 0.0
            else:
                target[key] = float(val)
        elif _type == PARSE_TYPE_STR:
            target[key] = (val.encode("utf-8")).replace("\\n", "\n")
        elif _type == PARSE_TYPE_INT_ARRAY:
            if val == "" or val == -1 or val == 0:
                target[key] = []
            else:
                val = normalize(val)
                target[key] = [int(x) for x in re.split(",|\|", val)]
        elif _type == PARSE_TYPE_FLOAT_ARRAY:
            if val == "" or val == -1 or val == 0:
                target[key] = []
            else:
                val = normalize(val)
                target[key] = [float(x) for x in re.split(",|\|", val)]
        elif _type == PARSE_TYPE_STR_ARRAY:
            if val == "":
                target[key] = []
            else:
                target[key] = [(x.encode("utf-8")).replace("\\n", "\n") for x in re.split(",|\|", val)]
        elif _type == PARSE_TYPE_JSON:
            if val == "":
                # target[key] = None
                pass
            else:
                target[key] = unicode2str(json.loads(fixjson(val.encode('utf-8'))))
    except Exception, e:
        log.error("Parse file:%s, row:%d, key:%s, col:%d, type:%d, error" % (filename, row, key, col, val_type))
        raise e


def json_to_lua(json_name, json_data):
    ap1 = re.compile(r'\[')
    jsonstr1 = ap1.subn(r'{', json_data)
    ap2 = re.compile(r'\]')
    jsonstr2 = ap2.subn(r'}', jsonstr1[0])
    ap3 = re.compile(r'\"(\d+)\":')
    jsonstr3 = ap3.subn(r'[\1]:', jsonstr2[0])
    ap4 = re.compile(r'\"(\w+)\":')
    jsonstr = ap4.subn(r'["\1"]:', jsonstr3[0])
    luadata = 'cc.exports.' + json_name + "=" + jsonstr[0]
    luadata = luadata.replace(': ', '=')
    luadata = luadata.replace(', ', ', ')
    return luadata


def convert_data(xlsx, sheet_idx, key, compress_table, _resource_dir):
    data = dict()
    parse_xls(_resource_dir + TABLE_ROOT_DIR + xlsx + ".xlsx", sheet_idx, key, data)
    if compress_table == yes:
        jsonstr = json.dumps(data, ensure_ascii=False).decode("utf-8")
    else:
        jsonstr = json.dumps(data, indent=2, ensure_ascii=False).decode("utf-8")
    return jsonstr


def publish_client_table(compress_table, _resource_dir, _server_id):
    if os.path.exists(CLIENT_TABLE_OUT_DIR):
        shutil.rmtree(CLIENT_TABLE_OUT_DIR)
    os.makedirs(CLIENT_TABLE_OUT_DIR)
    lualistdata = "TableList = {\n"
    step = 0
    total_len = len(CLENT_TABLE_LIST)
    bar_length = 20
    for i in CLENT_TABLE_LIST:
        percent = int(step * bar_length / total_len)
        hashes = '#' * percent
        spaces = ' ' * (bar_length - len(hashes))
        sys.stdout.write("\rPercent: [%s] %d%%" % (hashes + spaces, step * 100 / total_len))
        sys.stdout.flush()
        lualistdata += "\"" + i + "\",\n"
        if os.path.exists(_resource_dir + TABLE_ROOT_DIR + i + _server_id + ".xlsx"):
            _xlsx = i + _server_id
        else:
            _xlsx = i
        json_data = convert_data(_xlsx, 0, CLENT_TABLE_LIST[i], compress_table, _resource_dir)
        lua_data = json_to_lua(i, json_data)
        filelua = codecs.open(CLIENT_TABLE_OUT_DIR + i + ".lua", "w", "utf-8")
        filelua.write(lua_data)
        filelua.close()
        step += 1
    percent = 20
    hashes = '#' * percent
    spaces = ' ' * (bar_length - len(hashes))
    sys.stdout.write("\rPercent: [%s] %d%%\n" % (hashes + spaces, step * 100 / total_len))
    sys.stdout.flush()
    lualistdata += "}"
    filelualist = codecs.open(CLIENT_TABLE_OUT_DIR + "TableList.lua", "w", "utf-8")
    filelualist.write(lualistdata)
    filelualist.close()


def publish_server_table(compress_table, _resource_dir, _server_id):
    if os.path.exists(SERVER_TABLE_OUT_DIR):
        shutil.rmtree(SERVER_TABLE_OUT_DIR)
    os.makedirs(SERVER_TABLE_OUT_DIR)
    step = 0
    total_len = len(SERVER_TABLE_LIST)
    bar_length = 20
    for i in SERVER_TABLE_LIST:
        percent = int(step * bar_length / total_len)
        hashes = '#' * percent
        spaces = ' ' * (bar_length - len(hashes))
        sys.stdout.write("\rPercent: [%s] %d%%" % (hashes + spaces, step * 100 / total_len))
        sys.stdout.flush()
        if os.path.exists(_resource_dir + TABLE_ROOT_DIR + i + _server_id + ".xlsx"):
            _xlsx = i + _server_id
        else:
            _xlsx = i
        json_data = convert_data(_xlsx, 0, SERVER_TABLE_LIST[i], compress_table, _resource_dir)
        file_handle = codecs.open(SERVER_TABLE_OUT_DIR + i + ".json", "w", "utf-8")
        file_handle.write(json_data)
        file_handle.close()
        step += 1
    percent = 20
    hashes = '#' * percent
    spaces = ' ' * (bar_length - len(hashes))
    sys.stdout.write("\rPercent: [%s] %d%%\n" % (hashes + spaces, step * 100 / total_len))
    sys.stdout.flush()


def publish(compress_table, _resource_dir, _server_id):
    log.debug("------------- tans client table begin -------------")
    publish_client_table(compress_table, _resource_dir, _server_id)
    log.debug("------------- tans client table end   -------------")
    log.debug("------------- tans server table begin -------------")
    publish_server_table(compress_table, _resource_dir, _server_id)
    log.debug("------------- tans server table end   -------------")
