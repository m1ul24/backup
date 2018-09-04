#!/bin/bash

# 日付
datestr=`date +%Y%m%d`

# SCP接続情報
USER=
IP=
PORT=
SEND_DIR=

# MySQL接続情報
MYSQL_USER=
MYSQL_PASS=
DB_NAME=

#サービス名
SERVICE_NAME=

# バックアップの保存ディレクトリ
BACKUP_DIR=

# バックアップ対象
TARGET_DIR=
TARGET_DIR_NAME=

# このサーバに保存しておくバックアップの数
NUMBER_TO_SAVE=30

STATUS=0

# $1 コピー元ファイル名
# $2 コピー先ファイル名
function scpfile(){
    eval "scp -P ${PORT} $1 ${USER}@${IP}:$2"
    if [ $? -ne 0 ]
    then
    echo "[ERROR]scp error. file=$1"
    STATUS=1
    fi
    return
}

# 古いバックアップの削除
function deletefile(){
    CNT=0
    for file in `ls -1t ${1}`   # 更新日付が新しい順にファイル名のリストを作成
    do
    CNT=$((CNT+1))

    if [ ${CNT} -le ${NUMBER_TO_SAVE} ]
        then
        continue
        fi
    eval "rm ${file}"
    done
    return
}

# ソースのバックアップ
eval "tar czf ${BACKUP_DIR}${SERVICE_NAME}_${datestr}.tar.gz -C ${TARGET_DIR} ${TARGET_DIR_NAME}"
if [ $? -ne 0 ]
then
    echo "[ERROR]tar error."
    STATUS=1
fi

# MySQLのバックアップ
eval "mysqldump --defaults-extra-file=<(printf '[mysqldump]\npassword=%s\n' ${MYSQL_PASS}) -u ${MYSQL_USER} --single-transaction ${DB_NAME} |gzip -c > ${BACKUP_DIR}${SERVICE_NAME}_${datestr}.sql.gz"
if [ $? -ne 0 ]
then
    echo "[ERROR]mysqldump error."
    STATUS=1
fi

# 古いバックアップを削除
deletefile "${BACKUP_DIR}${SERVICE_NAME}*.tar.gz"
deletefile "${BACKUP_DIR}${SERVICE_NAME}*.sql.gz"

# 最新のバックアップを別のサーバーへコピー
scpfile ${BACKUP_DIR}${SERVICE_NAME}_${datestr}.tar.gz ${SEND_DIR}
scpfile ${BACKUP_DIR}${SERVICE_NAME}_${datestr}.sql.gz ${SEND_DIR}

exit ${STATUS}
