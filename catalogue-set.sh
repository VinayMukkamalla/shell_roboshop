#!/bin/bash

set -euo pipefail

trap 'echo "there is an error $LINENO, command is : $BASH_COMMAND"' ERR 

user=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
mkdir -p $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
DIR_PATH=$(PWD)
MONGODB_HOST="mongodb.vinaymukkamalla.fun"

echo " script started execution at : $(date)" | tee -a $LOG_FILE

if [ $user -gt 0 ]; then
    echo "ERROR:: you are not allowed to run this script use root privilege"
    exit 1
fi


dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE
echo -e "Installing nodejs $G ...SUCCESS $N"

id roboshop  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else    
    echo -e "user already exists $Y ...Skipping $N"
fi

mkdir -p /app &>>$LOG_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE

cd /app &>>$LOG_FILE

rm -rf /app/*  &>>$LOG_FILE
unzip /tmp/catalogue.zip &>>$LOG_FILE


npm install &>>$LOG_FILE
echo -e "Installing dependencies $G ...SUCCESS $N"

cp $DIR_PATH/catalogue.service /etc/systemd/system/catalogue.service


systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE

systemctl start catalogue &>>$LOG_FILE
echo -e "starting catalogue $G ...SUCCESS $N"

cp $DIR_PATH/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE

dnf install mongodb-mongosh -y &>>$LOG_FILE
echo -e "Installing mongodb client $G ...SUCCESS $N"

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else        
    echo "catalogue products already loaded ...$Y SKipping $N"
fi

systemctl restart catalogue
echo -e "restarting catalogue $G ...SUCCESS $N"
