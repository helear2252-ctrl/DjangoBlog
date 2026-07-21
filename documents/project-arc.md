# DjangoBlog 專案結構與 Linux 部署前分析

> 分析日期：2026-07-21  
> 範圍：目前工作目錄的唯讀盤點，以及 `build_venv.bat`、`config.bat`、`download_db.bat` 的 Linux 轉換規劃。  
> 本次未修改任何程式碼或既有設定檔；本文件是唯一新增項目。

## 1. 專案摘要

此專案是以 Django 6.0 建立的單站式部落格：

- Django project：`DjangoBlog/`
- Django app：`article/`
- 資料庫：SQLite，預期位置為專案根目錄的 `db.sqlite3`
- 前端：Django templates 加上 `static/css/main.css`
- 認證：使用 Django 內建 `User`、session 與 authentication middleware
- 執行入口：`manage.py`、`DjangoBlog/wsgi.py`、`DjangoBlog/asgi.py`
- Windows 輔助腳本：建立虛擬環境、設定參數、下載 SQLite 資料庫，以及 Git 設定

目前架構適合開發或低流量單機部署；若遠端環境會水平擴充、多程序寫入或採用短暫檔案系統，SQLite 與下載式資料庫流程不適合作為長期正式環境方案。

## 2. 目錄與責任

```text
DjangoBlog/
├── manage.py                    # Django 管理命令入口
├── DjangoBlog/                  # project 設定與 WSGI/ASGI 入口
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── article/                     # 文章功能 app
│   ├── models.py                # Post model
│   ├── views.py                 # 首頁與新增文章 view
│   ├── admin.py                 # Post 後台註冊
│   ├── tests.py                 # 目前未見實質測試
│   └── migrations/              # 兩筆 schema migration
├── templates/
│   ├── base.html
│   ├── index.html
│   ├── article/create_post.html
│   ├── registration/login.html
│   └── components/              # header、footer
├── static/css/main.css
├── requirement.txt              # 腳本實際安裝的依賴清單
├── req.txt                      # 另一份較完整、版本固定的依賴清單
├── build_venv.bat               # Windows venv/依賴安裝
├── config.bat                   # Windows 下載及 Git 參數
├── download_db.bat              # Windows 資料庫下載
├── setup_git.bat                # Windows Git 初始化/設定（本次範圍外）
└── demo-index.html              # 獨立示範頁，不在 Django template 流程內
```

## 3. 應用程式資料流

1. 使用者請求由 `DjangoBlog/urls.py` 分派。
2. 首頁 view 查詢 `Post.objects.all()`，model 依 `pub_date` 反向排序。
3. `index.html` 顯示文章清單及登入狀態。
4. 已登入使用者可進入新增文章頁，POST 後直接建立 `Post`，作者為 `request.user`。
5. `Post.author` 關聯 Django 內建 `User`；migration 已包含此欄位。
6. HTML 由共用 `base.html`、header/footer 與頁面 template 組成；CSS 從 Django staticfiles 載入。

## 4. 目前已確認的阻擋問題

以下不是 Linux shell 語法問題，而是目前專案本身會影響啟動或部署的問題；轉換腳本不會自動解決它們。

### P0：URL 設定引用不存在的模組與函式

`DjangoBlog/urls.py` 目前包含：

- `include('article.urls')`，但專案中沒有 `article/urls.py`。
- `article_views.user_login` 與 `article_views.user_logout`，但 `article/views.py` 沒有這兩個函式。

載入 root URLconf 時預期會失敗。需決定要恢復 Django 內建的 `django.contrib.auth.urls`，或補齊 app URLconf 與自訂 view。

### P0：base template 尚有 Git merge conflict 標記

`templates/base.html` 包含 `<<<<<<< HEAD`、`=======`、`>>>>>>> ...`。這些內容會污染或破壞實際輸出的 HTML，且兩側 template block 名稱也不一致。部署前需人工選定正確版本並完成合併。

### P1：正式環境安全設定尚未完成

`DjangoBlog/settings.py` 目前：

- `SECRET_KEY` 寫死在版本庫內容中。
- `DEBUG = True`。
- `ALLOWED_HOSTS = ['*']`。
- 未見 `CSRF_TRUSTED_ORIGINS`、HTTPS cookie、安全轉址等正式環境設定。

建議從環境變數讀取 secret、debug flag 與 host/origin 清單；正式環境關閉 debug，並限定實際網域。

### P1：static files 的正式部署流程不完整

目前僅設定 `STATIC_URL = 'static/'`；工作樹中的設定還移除了 `STATICFILES_DIRS`，且未設定 `STATIC_ROOT`。正式部署通常需要 `collectstatic`，再由反向代理、平台靜態服務或 WhiteNoise 提供檔案。

### P1：依賴清單有兩份且內容不一致

- `build_venv.bat` 使用 `requirement.txt`，其中為 `Django==6.0`、`markdown>=3.5`。
- `req.txt` 固定了 Django 的傳遞依賴與 `tzdata`，但沒有 `markdown`。

應指定單一權威清單（一般慣例命名為 `requirements.txt`），避免本機與遠端安裝結果不同。若採 WSGI/ASGI 正式服務，清單也需加入選定的 server，例如 Gunicorn 或 Uvicorn；目前兩份都沒有 production server。

### P2：缺少可驗證行為的測試

`article/tests.py` 目前未見實質測試。至少應涵蓋首頁、登入、建立文章的權限與 POST 驗證，並在部署前執行 Django system check 與測試。

## 5. 三個 Windows 腳本的現況與 Linux 對應

建議不要讓 `.bat` 內容偽裝成 Linux 腳本；改為新增或重新命名為 `.sh`：

| 現有檔案 | 建議 Linux 名稱 | 責任 |
|---|---|---|
| `build_venv.bat` | `build_venv.sh` | 檢查 Python、建立 `.venv`、升級 pip、安裝依賴 |
| `config.bat` | `config.sh` | 提供下載設定；敏感或環境特定值優先由環境變數注入 |
| `download_db.bat` | `download_db.sh` | 載入設定，以 curl 下載並驗證資料庫檔案 |

三個 shell 檔案都應採 LF 換行、UTF-8、以 `#!/usr/bin/env bash` 開頭，並設為可執行（`chmod +x ...`）。建議使用 `set -Eeuo pipefail` 讓未處理錯誤、未定義變數及 pipeline 失敗能立即終止。

### 5.1 `build_venv.bat` 轉換要點

現有行為：

- 用 `python --version` 檢查 Python。
- 若 `.venv` 不存在則建立。
- 直接以 `.venv\\Scripts\\python.exe` 升級 pip、安裝 `requirement.txt`。
- 用 `%errorlevel%` 判斷錯誤，並以 `pause` 等待使用者。

Linux 版本應：

- 優先檢查 `python3`；不要假設 `python` 一定存在或指向 Python 3。
- 用 `python3 -m venv .venv` 建立環境。
- 不必 `source .venv/bin/activate`；直接呼叫 `.venv/bin/python -m pip ...` 更適合非互動部署。
- 移除 `pause`、`nul`、`%errorlevel%` 與 Windows 路徑。
- 從腳本自身位置解析專案根目錄，避免從其他 working directory 執行時找錯檔案。
- 先統一依賴檔名，再決定安裝哪一份。
- 若遠端 OS 缺少 venv 套件，需先安裝對應系統套件（例如 Debian/Ubuntu 的 `python3-venv`）；這應由主機建置程序處理。

### 5.2 `config.bat` 轉換要點

現有行為：

- 設定 Google Drive `FILE_ID`。
- 以 `%~dp0` 將 `DB_PATH` 指向腳本目錄下的 `db.sqlite3`。
- 組合 `DOWNLOAD_URL`。
- 同時保存 Git user name/email。

Linux 版本應：

- 使用 shell 變數及 `${VAR}` 語法，若需讓子程序取得則 `export`。
- 以 `BASH_SOURCE[0]` 推導設定檔所在目錄，避免依賴呼叫者所在目錄。
- 使用 `${FILE_ID:-預設值}` 形式允許部署環境覆寫。
- 路徑一律加雙引號。
- 將 Git 身分設定移出資料庫下載設定；它與 runtime/deployment 無關，且 `setup_git.bat` 也仍是 Windows 專用。
- 若未來設定包含密碼、token 或正式 secret，不應提交進 Git；應改由部署平台的 secret/environment 管理。

### 5.3 `download_db.bat` 轉換要點

現有行為：

- `call config.bat` 載入設定。
- 優先用 `curl.exe`，否則改用 PowerShell。
- `curl -L` 下載至 `db.sqlite3`，只檢查命令 exit code 與檔案是否存在。

Linux 版本應：

- 用 `source` 載入 `config.sh`，並在載入前驗證檔案存在。
- 明確以 `command -v curl` 檢查 curl；若要支援 wget，應明確設計 fallback，不再依賴 PowerShell。
- 使用 `curl --fail --location --show-error --silent`，讓 HTTP 4xx/5xx 成為錯誤。
- 先下載到同目錄暫存檔，驗證成功後再以原子性 `mv` 覆蓋目標，避免下載中斷時毀掉既有 DB。
- 至少驗證檔案非空；更穩妥可檢查 SQLite header，並用 `sqlite3` 執行 `PRAGMA quick_check`（若主機有安裝）。
- Google Drive 對較大檔案可能要求確認 token，單純 `uc?export=download&id=...` 不保證永遠取得實際 SQLite 檔；應檢查回傳內容不是 HTML。長期建議改用物件儲存或正式資料庫備份管道。
- 若資料庫含真實帳號或內容，需確認存取權限與傳輸/靜態加密策略。

## 6. 建議的 Linux 部署順序

1. 先解決 URLconf 缺檔／缺函式與 `base.html` merge conflict。
2. 整併依賴清單，加入正式 application server。
3. 將 Django 正式設定改由環境變數控制，補齊 static files 策略。
4. 將三個 `.bat` 轉成 `.sh`，採安全錯誤處理、穩定路徑解析及原子下載。
5. 建立虛擬環境並安裝依賴。
6. 如確實要沿用 SQLite，先安全下載／驗證 DB；否則建立正式 DB 並執行 migration。
7. 執行 `python manage.py check --deploy`、`python manage.py migrate`、`python manage.py collectstatic --noinput` 與測試。
8. 以 systemd、容器或部署平台啟動 WSGI/ASGI server，並在前方配置 HTTPS reverse proxy。
9. 驗證首頁、登入／登出、admin、文章建立及靜態檔案。

## 7. SQLite 部署限制

- SQLite 是單一檔案，必須放在持久化磁碟，且執行服務的 Linux 使用者需有讀寫權限。
- 多實例不能安全共享一般本機 SQLite 檔；短暫容器重啟也可能遺失資料。
- 每次部署重新下載並覆蓋 `db.sqlite3` 可能覆寫線上新資料，因此下載腳本不宜無條件放進每次啟動流程。
- 若網站會持續寫入或擴充，建議改用 PostgreSQL，並將資料匯入與 schema migration 分開管理。

## 8. 工作樹狀態與範圍提醒

分析時 Git 顯示已有使用者尚未提交的變更：

- `DjangoBlog/asgi.py`
- `DjangoBlog/settings.py`
- `DjangoBlog/urls.py`
- `DjangoBlog/wsgi.py`
- `requirement.txt`

其中部分可能只是換行格式差異，但 `settings.py`、`urls.py`、`requirement.txt` 有實質差異。本次未修改或還原它們。後續實作 Linux 腳本時，也應保留這些既有變更並避免混入無關修正。

## 9. 下一階段建議交付物

若下一步開始實作，建議範圍明確拆成：

- 建立 `build_venv.sh`、`config.sh`、`download_db.sh`。
- 決定是否保留 `.bat` 供 Windows 使用，或完全移除；若團隊仍跨平台，建議並存。
- 補一段 Linux 執行說明（權限、環境變數、命令順序）。
- 另開一個修復批次處理上述 P0/P1 問題，避免把應用修復與 OS 腳本遷移混成同一次變更。

