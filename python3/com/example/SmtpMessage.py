#!/usr/bin/python3

from smtplib import SMTP
from email.header import Header
from email.mime.text import MIMEText

def main():
    sender = 'sixuechao@163.com'
    receivers = ['949136547@qq.com']
    message = MIMEText('用Python发送邮件的事例','plain','utf-8')
    message['From'] = Header('ss','utf-8')
    message['To'] = Header('sss','utf-8')
    message['Subject'] = Header('示例代码验证邮件','utf-8')
    smtper = SMTP('smtp.126.com')
    smtper.login(sender,'')
    smtper.send_message(sender,receivers,message.as_string())
    print('邮件发送完成')

if __name__ == '__main__':
    main()