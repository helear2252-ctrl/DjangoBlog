@echo off
:: =====================================================================
:: Configuration Parameters for Database Download
:: =====================================================================

:: Google Drive File ID for db.sqlite3
:: https://drive.google.com/file/d/1WV6oZWj9UDUvpDT281Z_ba04Ph0Yt_SA/view?usp=sharing
set "FILE_ID=1WV6oZWj9UDUvpDT281Z_ba04Ph0Yt_SA"

:: Local path where the database will be saved
set "DB_PATH=%~dp0db.sqlite3"

:: Direct download link constructed from FILE_ID
set "DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=%FILE_ID%"

set "GIT_USER_NAME=JUN WEI"
set "GIT_USER_EMAIL=helear2252@gmail.com"