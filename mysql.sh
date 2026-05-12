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
 
dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "Installing mysql server"

systemctl enable mysqld &>>$LOGS_FILE
VALIDATE $? "Enable mysql"

systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "start mysql"

#get the password from user
mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGS_FILE
VALIDATE $? "Setting Root Password"


