#!/bin/bash

if [ $# -lt 1 ];then 
	echo -e "\nUsage: ./install_model.sh [user_id] [model_name]\r"
	echo -e "Exemple: ./install_model.sh 1 trader\r"
	exit 1
fi 

USER_ID=$1
MODEL_NAME=$2

USERS_DIR=/users
INSTALL_DIR=/home/MSF
MODELS_DIR=/Models

mkdir -p ${USERS_DIR}/${USER_ID}/models/${MODEL_NAME}
touch ${USERS_DIR}/${USER_ID}/models/${MODEL_NAME}/eng-cts.sdic
touch ${USERS_DIR}/${USER_ID}/models/${MODEL_NAME}/fre-cts.sdic
mkdir -p ${MODELS_DIR}/${USER_ID}
ln -s ${MODELS_DIR}/${MODEL_NAME} ${MODELS_DIR}/${USER_ID}/${MODEL_NAME}

