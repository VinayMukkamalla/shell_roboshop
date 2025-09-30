#!/bin/bash

user=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-Roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
START_TIME=$(date +%s)
mkdir -p $LOG_FOLDER
DIR_PATH=$PWD
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

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

cp $DIR_PATH/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "starting rabbitmq server"

id roboshop  &>>$LOG_FILE
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
else    
    echo -e "user already exists $Y ...Skipping $N"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "setting permissions for roboshop user"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo "Total time taken to execute script : $TOTAL_TIME seconds"