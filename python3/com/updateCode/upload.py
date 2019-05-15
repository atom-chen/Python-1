#!/usr/bin/python3

import os
import updateAssetsConfig
from ftplib import FTP

_XFER_FILE = 'FILR'
_XFER_DIR = 'DIR'

class Sfer(object):
    def __init__(self):
        self.ftp = None