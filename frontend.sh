#!/bin/bash

LOGS_FLODER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
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

dnf install nginx -y &>>LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>LOG_FILE
VALIDATE $? "starting Nginx"

rm -rf /usr/share/nginx/html/* &>>LOG_FILE
VALIDATE $? "Removing Default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>LOG_FILE
VALIDATE $? "Downloading Frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>LOG_FILE
VALIDATE $? "Extract Frontend Code"

systemctl restart nginx

