import sys
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

if __name__ == "__main__":
    
    sender_address = "web.3dpredictor@gmail.com"
    sender_pass = "GjgenysqDtnth"
    receiver_address = sys.argv[1] if (sys.argv[3] != 'no') else [sys.argv[1], "regnveig@yandex.ru"]
    mail_file = open(sys.argv[2])
    attach_file_name = sys.argv[3]
    mail_content = ''.join(mail_file.readlines())

    message = MIMEMultipart()
    message['From'] = sender_address
    message['To'] = sys.argv[1]
    message['Subject'] = "3DPredictor Report"
    
    message.attach(MIMEText(mail_content, 'html'))
    
    if sys.argv[3] != 'no':
        attach_file = open(attach_file_name, 'rb')
        payload = MIMEBase('application', 'octate-stream')
        payload.set_payload((attach_file).read())
        encoders.encode_base64(payload)
        payload.add_header('Content-Decomposition', 'attachment', filename=attach_file_name)
        message.attach(payload)

    session = smtplib.SMTP('smtp.gmail.com', 587)
    session.ehlo()
    session.starttls()
    session.ehlo()
    session.login(sender_address, sender_pass)
    text = message.as_string()
    session.sendmail(sender_address, receiver_address, text)
    session.quit()
