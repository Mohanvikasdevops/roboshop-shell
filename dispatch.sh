#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-shell"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.109v.store

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
 
dnf install golang -y &>>$LOGS_FILE
VALIDATE $? "Installing golang server"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "creating system user"  
else
    echo -e "Roboshop user already exist ... $Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading dispatch code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/dispatch.zip
VALIDATE $? "Unzip dispatch code"

cd /app 
go mod init dispatch
go get 
go build
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOGS_FILE
VALIDATE $? "Created  systemctl service"

systemctl daemon-reload  &>>$LOGS_FILE
systemctl enable dispatch &>>$LOGS_FILE
systemctl start dispatch &>>$LOGS_FILE
VALIDATE $? "start and enable dispatch"

