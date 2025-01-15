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
dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing Mysql Server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled Mysql Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started Mysql Server"

mysql -h 172.31.90.163 -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "Mysql root password is not setup, setting now" &>>$LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting up root password"
else
    echo "Mysql root password is Already setup..$Y SKIPPING $N" | tee -a $LOG_FILE
fi


