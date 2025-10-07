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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "adding system user "
else    
    echo -e "user already exists $Y ...Skipping $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory "

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment application "

cd /app &>>$LOG_FILE
VALIDATE $? "changing to app Directory "

rm -rf /app/*  &>>$LOG_FILE
VALIDATE $? " removing existing code in app Directory "

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment application "

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing application dependencies"

cp $DIR_PATH/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? " creating payment service"

systemctl daemon-reload &>>$LOG_FILE

systemctl enable payment &>>$LOG_FILE
VALIDATE $? " enabling payment service"

systemctl start payment &>>$LOG_FILE
VALIDATE $? " starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo "Total time taken to execute script : $TOTAL_TIME seconds"