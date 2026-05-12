#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-shell"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then  
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi


#By default shell will not execute, only executed when called
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "Disabling redis server"

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "Enabling redis server"
 
dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "Installing redis server"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>>$LOGS_FILE
sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>>$LOGS_FILE
VALIDATE $? "Allowing remote connections"

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "Enable redis"

systemctl start redis &>>$LOGS_FILE
VALIDATE $? "start redis"



