#! /usr/bin/env bash
設定-e

echo  " ============================================= "
echo  "正在從 Google 雲端硬碟下載資料庫... "
echo  " ============================================= "

SCRIPT_DIR= " $( cd " $( dirname " ${BASH_SOURCE[0]} " ) "  && pwd ) "

如果[ -f  " ${SCRIPT_DIR} /config.sh " ] ; 則
    來源 “ ${SCRIPT_DIR} /config.sh ”
別的
    echo  " [錯誤] 未找到 config.sh 檔案。"
    出口1
菲

echo  "目標：${DB_PATH} "

如果 指令-v curl & > /dev/null ； 則
    echo  "使用 curl 下載... "
    curl -L " ${DOWNLOAD_URL} " -o " ${DB_PATH} "
elif  command -v wget & > /dev/null ;  then
    echo  "使用 wget 下載... "
    wget -O " ${DB_PATH} "  " ${DOWNLOAD_URL} "
別的
    echo  " [錯誤] curl 和 wget 皆未安裝。"
    出口1
菲

如果[ !  -s  " ${DB_PATH} " ] ; 則
    echo  " [錯誤] 資料庫檔案未建立或為空。"
    出口1
菲

echo  " ============================================= "
echo  "資料庫下載成功！"
echo  "已儲存為：${DB_PATH} "
echo  " ============================================= "