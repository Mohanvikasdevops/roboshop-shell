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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOGS_FILE
VALIDATE $? "Copying rabbitmq Repo"

# 2. Clean the cache so the new repo is detected immediately
dnf clean all &>>$LOGS_FILE

# 3. Install the mandatory dependency first
dnf install socat -y &>>$LOGS_FILE
VALIDATE $? "Installing socat dependency"

dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "Enable rabbitmq-server"

systemctl start rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "start rabbitmq-server"

# Add user only if it doesn't exist
rabbitmqctl list_users | grep -q roboshop
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>>$LOGS_FILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exists ... $Y skipping $N"
fi

# Set permissions
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGS_FILE
VALIDATE $? "Setting user permissions"



