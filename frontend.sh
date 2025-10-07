#!/bin/bash

user=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
START_TIME_TIME=$(date +%s)
mkdir -p $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
DIR_PATH=$PWD

echo " script started execution at : $(date)" | tee -a $LOG_FILE

if [ $user -gt 0 ]; then
    echo "ERROR:: you are not allowed to run this script use root privilege"
    exit 1
fi

VALIDATE(){
    if [ $1 -gt 0 ]; then
        echo -e " $2 ..$R Failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e " $2 ..$G Success $N" | tee -a $LOG_FILE

    fi

}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling default nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx version 1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? "enabling nginx "

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx "

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? " removing default html code from /usr/share/nginx/html path"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend application"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "changing to /usr/share/nginx/html path"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend application"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "removing default nginx configuration"

cp $DIR_PATH/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "adding nginx configuration "

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restarting nginx"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo "Total time taken to execute script : $TOTAL_TIME seconds"
