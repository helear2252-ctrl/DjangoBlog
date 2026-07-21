#! /usr/bin/env bash
設定-e

echo  " ============================================= "
echo  "正在設定Python虛擬環境... "
echo  " ============================================= "

SCRIPT_DIR= " $( cd " $( dirname " ${BASH_SOURCE[0]} " ) "  && pwd ) "

#檢查是否已安裝 Python 3
如果 !  command -v python3 & > /dev/null ; 則
    echo  " [錯誤] python3 未安裝或不在 PATH 環境變數中。"
    出口1
菲

#建立虛擬環境
如果[ !  -d  " ${SCRIPT_DIR} /.venv " ] ; 則
    echo  "正在 .venv 中建立虛擬環境... "
    python3 -m venv " ${SCRIPT_DIR} /.venv "
    echo  "虛擬環境建立成功。"
別的
    echo  " .venv 已存在。跳過建立。"
菲

#升級 pip
echo  "正在升級 pip... "
" ${SCRIPT_DIR} /.venv/bin/python " -m pip install --upgrade pip

#安裝依賴項
如果[ -f  " ${SCRIPT_DIR} /requirement.txt " ] ; 則
    echo  "正在從 requirements.txt 安裝依賴項... "
    " ${SCRIPT_DIR} /.venv/bin/pip " install -r " ${SCRIPT_DIR} /requirement.txt "
別的
    echo  " [警告] 未找到 requirements.txt 檔案。跳過安裝。"
菲

echo  " ============================================= "
echo  "設定成功完成！"
echo  " ============================================= "