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
 
dnf install python3n gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing python server"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "creating system user"  
else
    echo -e "Roboshop user already exist ... $Y skipping $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading payment code"

cd /app &>>$LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unzip payment code"

cd /app 
pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
VALIDATE $? "Created  systemctl service"

systemctl daemon-reload  &>>$LOGS_FILE
systemctl enable payment &>>$LOGS_FILE
systemctl start payment &>>$LOGS_FILE
VALIDATE $? "start and enable payment"

