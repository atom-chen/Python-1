#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import os
import shutil

import table
# import md5
import log

RES_DIR = "../client/res"

yes = "y"
no = "n"
_png_compress = "n"
_compress_table = "n"
_resource_dir = ".."
_server_id = ""
log.info("============== publish excel begin  ==============")
table.publish(_compress_table, _resource_dir, _server_id)
log.info("============== publish excel end    ==============")