#!/bin/bash

LOGS_FLODER="/var/log/expense"
SCRIPT_NAME=$(echo "16-redirectors.sh" | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FLODER
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ] 
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is...$G success $N" | tee -a $LOG_FILE
    fi
}
echo "script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Diasable defaults nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabled nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs:20"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "expense user not exits.. $G creating $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "creating expense user"
else 
    echo -e "expense user Already exits.. $Y SKIPPING $N" 
fi   

mkdir -p /app
VALIDATE $? "creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading code for backend application"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip
VALIDATE $? "Extracting code for backend application"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shellscript/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "istall Mysql for backend application"

mysql -h 172.31.90.163 -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "schema loading is sucessful"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "re-start backend"

