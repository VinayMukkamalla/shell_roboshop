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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "disabling redis "

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "enabling redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing redis 7"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "updating redis configuration allowing access"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "enabling redis "

systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting redis "

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo "Total time taken to execute script : $TOTAL_TIME seconds"