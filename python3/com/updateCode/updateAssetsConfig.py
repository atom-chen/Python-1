#!/usr/bin/python3

import os
import sys
# --------------------------请配置以下信息-----------------------------

# 版本号
VersionNumber = "1.0.0"
# 版本号文件夹
VersionString = VersionNumber.replace('.', '')
IsOld = True

isInIOSReview = False

isInAndroidReview = False

isIOSReviewing = False

isAndroidReviewing = False

# 项目名称(需要作为路径使用,不允许使用非法字符)
ProjectName = 'Card'
# ftp服务器更新的项目目录名称
FTPProjectName = 'Card/base'

FTPProjectName_AppStore_old = 'Card/AppStore_20171223'
FTPProjectName_AppStore_new = 'Card/AppStore_20180116'

FTPProjectName_AndroidStore_old = 'Card/AndroidStore_20171212'
FTPProjectName_AndroidStore_new = 'Card/AndroidStore_20171212'  # 'caixing_yule/AndroidStore_20180109'

# --------------------------配置信息结束-----------------------------
# --------------------------以下信息不需要配置------------------------
print('     [1]:正常更新')
print('     [2]:正常更新（ios正在审核）')
print('     [3]:正常更新（android正在审核）')
print('     [4]:正常更新（ios和android都在审核）')
print('     [5]:ios审核更新')
print('     [6]:安卓审核更新')

ctrlIndex = input('选择操作，输入数字编号:')
if ctrlIndex == '1':
    isIOSReviewing = False
elif ctrlIndex == '2':
    isIOSReviewing = True
elif ctrlIndex == '3':
    isAndroidReviewing = True
elif ctrlIndex == '4':
    isIOSReviewing = True
    isAndroidReviewing = True
elif ctrlIndex == '5':
    isInIOSReview = True
elif ctrlIndex == '6':
    isInAndroidReview = True
else:
    print('编号输入错误!')
    try:
        sys.exit(0)
    except:
        print("退出进程")
    finally:
        print("cleanup")

print('  ')
print('<<<=======平台选择完成========>>>')
print('  ')

# 发布前资源拷贝路径
ReleasePath = "/Users/ss/work/Card/backup/release"

if isInIOSReview == True:
    FTPProjectName = FTPProjectName_AppStore_new
    
if isInAndroidReview == True:
    FTPProjectName = FTPProjectName_AndroidStore_new

# 生成热更获取网址
UpdateWebsite = "http://www.quanlaigame.com/client/%s" % FTPProjectName

# appstore cdn刷新网址
AppStoreUpdateWebsites = [
    "http://www.quanlaigame.com/client/%s" % FTPProjectName_AppStore_new,
    "http://www.quanlaigame.com/client/%s" % FTPProjectName_AppStore_old,
    "http://www.quanlaigame.com/client/%s" % FTPProjectName_AndroidStore_new,
    "http://www.quanlaigame.com/client/%s" % FTPProjectName_AndroidStore_old,
    "http://www.quanlaigame.com/client/caixing_yule",
]

# 更新路径 格式为:   本地相对路径 : 服务器相对路径

Paths = {}
ManifestPahts = {}
# 审核包不需要上传res 和 lua_classes
if isInIOSReview == False and isInAndroidReview == False: 
    Paths = {
        '1' : ['%s/%s/%s/lua_classes' % (ReleasePath, ProjectName, VersionString), './%s/update/%s/lua_classes' % (FTPProjectName, VersionString)],
        '2' : ['%s/%s/%s/res' % (ReleasePath, ProjectName, VersionString), './%s/update/%s/res' % (FTPProjectName, VersionString)],
    }

if isInIOSReview == True:
    ManifestPahts['1'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
    ManifestPahts['2'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
elif isInAndroidReview == True:
    ManifestPahts['1'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]
    ManifestPahts['2'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]
else:
    ManifestPahts['1'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName]
    ManifestPahts['2'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName]
    ManifestPahts['3'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_old]
    ManifestPahts['4'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_old]
    ManifestPahts['5'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_old]
    ManifestPahts['6'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_old]
    if isIOSReviewing == False and isAndroidReviewing == False:
        ManifestPahts['7'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
        ManifestPahts['8'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
        ManifestPahts['9'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]
        ManifestPahts['10'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]
    elif isIOSReviewing == False:
        ManifestPahts['7'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
        ManifestPahts['8'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AppStore_new]
    elif isAndroidReviewing == False: 
        ManifestPahts['7'] = ['%s/%s/%s/project.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]
        ManifestPahts['8'] = ['%s/%s/%s/version.manifest' % (ReleasePath, ProjectName, VersionString), './%s' % FTPProjectName_AndroidStore_new]

assetsXml = ''
assetsMoreXml = ''

def getVersion(versionNumber, versionString):
    return '{\n\
    "packageUrl" : "%s/update/%s",\n\
    "remoteVersionUrl" : "%s/version.manifest",\n\
    "remoteManifestUrl" : "%s/project.manifest",\n\
    "version" : "%s",\n\
    "engineVersion" : "Cocos2d-x v3.10"\n\
}' % (UpdateWebsite, versionString, UpdateWebsite, UpdateWebsite, versionNumber)

def getProject(versionNumber, versionString, assets, newassets):
    return '{\n\
    "packageUrl" : "%s/update/%s",\n\
    "remoteVersionUrl" : "%s/version.manifest",\n\
    "remoteManifestUrl" : "%s/project.manifest",\n\
    "version" : "%s",\n\
    "engineVersion" : "Cocos2d-x v3.10",\n\n\
    "assets" : {\
    %s\n\
    },\n\
    "searchPaths" : [\n\
    ]\n}' % (UpdateWebsite, versionString, UpdateWebsite, UpdateWebsite, versionNumber, newassets)