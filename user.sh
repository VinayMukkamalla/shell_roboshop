#!/bin/bash

user=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
START_TIME=$(date +%s)
mkdir -p $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
DIR_PATH=$(PWD)
MONGODB_HOST="mongodb.vinaymukkamalla.fun"

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs "

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs version 20 "

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs "

id roboshop  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "adding system user "
else    
    echo -e "user already exists $Y ...Skipping $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory "

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE

cd /app &>>$LOG_FILE

rm -rf /app/*  &>>$LOG_FILE
unzip /tmp/user.zip &>>$LOG_FILE


npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies "

cp $DIR_PATH/user.service /etc/systemd/system/user.service


systemctl daemon-reload

systemctl enable user &>>$LOG_FILE
VALIDATE $? "enlabling user "

systemctl start user &>>$LOG_FILE
VALIDATE $? "starting user service "

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo "Total time taken to execute script : $TOTAL_TIME seconds"