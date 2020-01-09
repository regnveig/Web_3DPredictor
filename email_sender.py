 
def send_mail(cc, msg):
    fromaddr = 'zakazserov@gmail.com'
    username = 'zakazserov@gmail.com'
    password = 'razvitie'
    server = smtplib.SMTP('smtp.gmail.com:587')
    server.ehlo()
    server.starttls()
    server.login(username, password)
    msg2 = "\r\n".join(["From: zakazserov@gmail.com", "To: " + toaddrs, "Subject: Семинар", "Cc: ", msg])
    server.sendmail(fromaddr, toaddrs, msg2)
    server.quit()
