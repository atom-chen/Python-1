#!/usr/bin/python3

###-------------请配置一下信息----------------###

# "https://www.japanesepod101.com/japanese-vocabulary-lists/?page=2&search=&order=popular"
WORD_URL_1 = "https://www.google.com/search?ei=lSivXOuLLoPI5gLs57foDg&q="
WORD_URL_2 = "+site%3Adictionary.goo.ne.jp&oq="
WORD_URL_3 = "+site%3Adictionary.goo.ne.jp&gs_l=psy-ab.3...0.0..6861...0.0..0.0.0.......0......gws-wiz.XoE-AHMKmMg"

WORD_URL_JH_1 = "https://dict.hjenglish.com/jp/jc/"
WORD_URL_JH_2 = "https://dict.hjenglish.com/jp/jc/"

WORD_URL_K = "https://www.japandict.com/"
THREAD_Max_NUM = 1000

ALL_JA_WORD = "word_ja.html"
DOC_JA_NO_DOWN = "doc_no_down/"
DOC_JA_DOWN = "doc_down/"
DOC_JA_DOWN_PARSE = "doc_down_parse/"
ALL_DOWN_JA_WORD = "down_ja.html"

STR_404 = "IS_404"
JS_DATA_FILE = "js_reload.html"
global JS_RELOAD_LIST
JS_RELOAD_LIST = []

global down_file_name_list
down_file_name_list = []

HIRAGANA = ['ぁ', 'あ', 'い', 'う', 'ぇ', 'え', 'お', 'か', 'が', 'き', 'ぎ', 'く',
            'ぐ', 'け', 'げ', 'こ', 'ご', 'さ', 'ざ', 'し', 'じ', 'す', 'ず', 'せ', 'ぜ', 'そ', 'ぞ', 'た',
            'だ', 'ち', 'ぢ', 'っ', 'つ', 'づ', 'て', 'で', 'と', 'ど', 'な', 'に', 'ぬ', 'ね', 'の', 'は',
            'ば', 'ぱ', 'ひ', 'び', 'ぴ', 'ふ', 'ぶ', 'ぷ', 'へ', 'べ', 'ぺ', 'ほ', 'ぼ', 'ぽ', 'ま', 'み',
            'む', 'め', 'も', 'ゃ', 'や', 'ゅ', 'ゆ', 'ょ', 'よ', 'ら', 'り', 'る', 'れ', 'ろ', 'わ', 'ゐ', 'ゑ', 'を', 'ん', 'ゝ', 'ゞ']

KATAGANA = ['ア', 'イ', 'ウ', 'エ', 'オ',
            'カ', 'キ', 'ク', 'ケ', 'コ',
            'サ', 'シ', 'ス', 'セ', 'ソ',
            'タ', 'チ', 'ツ', 'テ', 'ト',
            'ハ', 'ヒ', 'フ', 'ヘ', 'ホ',
            'ナ', 'ニ', 'ヌ', 'ネ', 'ノ',
            'マ', 'ミ', 'ム', 'メ', 'モ',
            'ラ', 'リ', 'ル', 'レ', 'ロ',
            'ヤ', 'ユ', 'ヨ', 'ン',
            'ガ', 'ギ', 'グ', 'ゲ', 'ゴ',
            'ザ', 'ジ', 'ズ', 'ゼ', 'ゾ',
            'ダ', 'ヂ', 'ヅ', 'デ', 'ド',
            'バ', 'ビ', 'ブ', 'ベ', 'ボ',
            'パ', 'ピ', 'プ', 'ペ', 'ポ']


Doc_file1 = "pageDataDoc_1/"
P_file1 = Doc_file1 + "page_.html"

Doc_file2 = "pageDataUrl_1"
P_file2 = Doc_file2 + "pageUrl_.html"

Two_UrlDoc = "twoUrlDoc/"
Doc_file3 = "file3Doc/"
URL_DOC_THREE = "threeUrlDoc/"
URL_FILE_THREE = "threeUrlFile.html"

urlPageTips_1 = "<!-- <page: "
urlPageTips_2 = "> -->"
All_Url = "AllUrl_1.html"
URL_DATA_DOC = Doc_file1
URL_DATA_FILE = "urlDataFile.html"

URL_DATA_PARSE_DOC_1 = "urlDataParseDoc_2/"
URL_DATA_PARSE_FILE_FIX = "parseFile_.json"

Q_JA = "Q_ja"
Q_EN = "Q_en"
A_JA = "A_ja"
A_JA_A = "A_ja_a"
A_EN = "A_en"

Q_1 = "Q1"
Q_2 = "Q2"

# IP_TEXT_1 = "ip.txt"
# IP_TEXT_INDEX = "ip_index.txt"
# f_ip = open(IP_TEXT_1,"r")
# IP_Pool = f_ip.readlines()
# f_ip.close()
#
# # 得到随机头
# HEAD_TEXT_1 = "headers.txt"
# f_head = open(HEAD_TEXT_1,"r")
# USER_AGENT = f_head.readlines()
# f_head.close()

##共有方法
# 计算时间差，=格式：时分秒
def getTimeDiff(startTime,endTime):
    seconds = (startTime - endTime).seconds
    m, s = divmod(seconds, 60)
    h, m = divmod(m, 60)
    diff = ("%02d:%02d:%02d" % (h, m, s))
    return diff

##将字符串写入文件
def writeFile(fileName,str_):
    with open(fileName, 'a') as f:
        f.writelines(str_)
        f.write('\n')

# 清空文档
def truncateFile(path):
    with open(path, 'w') as f:
        f.truncate()

# 读取文档
def read(path):
    with open(path, 'r') as f:
        txt = []
        for s in f.readlines():
            txt.append(s.strip())
    return txt