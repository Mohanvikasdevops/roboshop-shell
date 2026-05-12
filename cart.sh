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

if [ $cartID -ne 0 ]; then  
    echo -e "$R Please run this script with root cart access $N" | tee -a $LOGS_FILE
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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling nodejs server"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs server"
 
dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs server"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    cartadd --system --home /app --shell /sbin/nologin --comment "roboshop system cart" roboshop &>>$LOGS_FILE
    VALIDATE $? "creating system cart"  
else
    echo -e "Roboshop cart already exist ... $Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading cart code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip
VALIDATE $? "Unzip cart code"

npm install 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOGS_FILE
VALIDATE $? "Created  systemctl service"

systemctl daemon-reload  &>>$LOGS_FILE
systemctl enable cart &>>$LOGS_FILE
systemctl start cart &>>$LOGS_FILE
VALIDATE $? "start and enable cart"








