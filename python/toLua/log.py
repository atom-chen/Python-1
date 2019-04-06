import sys
import ctypes

STD_INPUT_HANDLE = -10
STD_OUTPUT_HANDLE = -11
STD_ERROR_HANDLE = -12
RED = '\033[31m'
GREEN = '\033[32m'
YELLOW = '\033[33m'
MAGENTA = '\033[35m'
RESET = '\033[0m'
if sys.platform == 'win32':
    RED = 0x04
    GREEN = 0x02
    BULE = 0x01
    YELLOW = RED | GREEN
    MAGENTA = RED | BULE


def _print(s, color=None):
    if color and sys.stdout.isatty() and sys.platform != 'win32':
        print(color + "*" + s + RESET)
    elif sys.platform == 'win32':
        handle = ctypes.windll.kernel32.GetStdHandle(STD_OUTPUT_HANDLE)
        ctypes.windll.kernel32.SetConsoleTextAttribute(handle, color)
        print("*" + s)
        ctypes.windll.kernel32.SetConsoleTextAttribute(handle, RED | GREEN | BULE)
    else:
        print("*" + s)


def debug(s):
    _print(s, MAGENTA)


def info(s):
    _print(s, GREEN)


def warning(s):
    _print(s, YELLOW)


def error(s):
    _print(s, RED)
