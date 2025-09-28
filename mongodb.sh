#!/bin/bash

user=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-Roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
mkdir -p $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

echo " script started execution at : $(date)" | tee &>>$LOG_FILE

if [ $user -gt 0 ]; then
    echo "ERROR:: you are not allowed to run this script use root privilege"
    exit 1
fi

VALIDATE(){
    if [ $1 -gt 0 ]; then
        echo -e " $2 ..$R Failure $N"
        exit 1
    else
        echo -e " $2 ..$G Success $N"

    fi

}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling mongodb server"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting mongodb server"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing access to mongodb"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongodb server"