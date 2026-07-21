# 002 — Windows 批次檔轉換為 Linux Bash 腳本規劃

> 文件狀態：規劃階段  
> 建立日期：2026-07-21  
> 本階段限制：只建立本規劃文件，不修改 Django 主要程式碼、現有 `.bat` 或其他設定。

## 1. 目標

將下列 Windows 批次檔的既有功能轉換為 Linux 專用 Bash 腳本，以供後續遠端部署使用：

| Windows 來源 | Linux 目標 | 主要用途 |
|---|---|---|
| `build_venv.bat` | `build_venv.sh` | 建立 Python 虛擬環境並安裝依賴 |
| `config.bat` | `config.sh` | 提供資料庫下載所需參數 |
| `download_db.bat` | `download_db.sh` | 從遠端下載並驗證 SQLite 資料庫 |

本工作不包含修正 Django views、URLs、templates、settings、models 或 migrations。

## 2. 實作原則

- 使用 Bash，首行採 `#!/usr/bin/env bash`。
- 採 LF 換行與 UTF-8 編碼。
- 使用 `set -Eeuo pipefail`，發生錯誤時立即停止。
- 所有檔案路徑均加上雙引號。
- 從腳本自身位置推導專案根目錄，不依賴呼叫者當前目錄。
- 腳本應適合無人值守的遠端部署，不使用 `pause` 或互動式提示。
- 使用明確且非零的失敗 exit code；成功時回傳 `0`。
- 不把密碼、token、Django secret 或其他機密值寫入腳本。
- 不在此工作中自動安裝 Linux 系統套件或修改全域 Git 設定。
- 不在未完成驗證前覆蓋既有的 `db.sqlite3`。

## 3. 執行步驟

### 步驟 1：確認實作範圍與保留策略

1. 保留現有三個 `.bat`，新增對應 `.sh`，避免破壞目前 Windows 使用方式。
2. `setup_git.bat` 不在本次轉換範圍內。
3. 不處理先前分析發現的 Django URLconf、template merge conflict 或 production settings 問題。
4. 資料庫仍依現況放在專案根目錄的 `db.sqlite3`。

驗收條件：實作提交只包含三個新 Bash 腳本及必要的部署說明；若出現其他檔案變更，需逐項確認其必要性。

### 步驟 2：規劃共用的路徑及錯誤處理

每支腳本應先取得自身所在目錄，例如以 `BASH_SOURCE[0]` 搭配 `pwd -P` 取得絕對路徑。後續 `.venv`、依賴清單、設定檔與資料庫路徑都以此目錄為基準。

需統一以下輸出形式：

- 一般進度訊息輸出至 stdout。
- 錯誤訊息輸出至 stderr。
- 缺少必要命令、設定或下載失敗時立即結束。
- 不依賴 Windows 的 `%errorlevel%`、`%~dp0`、`where`、`nul` 或反斜線路徑。

驗收條件：從專案根目錄以外的位置呼叫腳本，仍能正確定位專案檔案。

### 步驟 3：建立 `config.sh`

預定內容與行為：

1. 提供目前 Google Drive `FILE_ID` 的預設值。
2. 允許部署環境透過既有環境變數覆寫 `FILE_ID`、`DB_PATH` 與 `DOWNLOAD_URL`。
3. `DB_PATH` 預設為專案根目錄下的 `db.sqlite3`。
4. `DOWNLOAD_URL` 預設由 `FILE_ID` 組成。
5. 只處理下載相關設定，不移植 `GIT_USER_NAME` 與 `GIT_USER_EMAIL`。
6. 若必要值為空，載入設定時立即報錯。

建議變數介面：

- `FILE_ID`
- `DB_PATH`
- `DOWNLOAD_URL`

驗收條件：直接載入 `config.sh` 後三個必要變數皆有值，且外部環境變數可以覆寫預設值。

### 步驟 4：建立 `build_venv.sh`

預定執行流程：

1. 檢查 Bash 執行環境。
2. 以 `command -v python3` 確認 Python 3 存在。
3. 輸出偵測到的 Python 版本。
4. 若 `.venv` 不存在，執行 `python3 -m venv .venv`。
5. 若 `.venv` 已存在，保留並重複使用。
6. 確認 `.venv/bin/python` 可執行。
7. 使用 `.venv/bin/python -m pip install --upgrade pip` 更新 pip。
8. 使用 `.venv/bin/python -m pip install -r ...` 安裝依賴。
9. 完成後輸出虛擬環境路徑與 Python 版本。

依賴檔案決策：

- 現有 `requirement.txt` 是原始批次檔實際使用的檔案，因此第一版先維持相同行為。
- `req.txt` 與 `requirement.txt` 內容不一致，後續應另立工作統一為慣例名稱 `requirements.txt`。
- 本次不得默默合併、刪除或重新產生依賴清單。

錯誤情境：

- 找不到 `python3`。
- Linux 未安裝 Python venv 支援，導致環境建立失敗。
- 找不到 `requirement.txt`。
- pip 更新或依賴安裝失敗。

驗收條件：

- 首次執行能建立 `.venv` 並安裝依賴。
- 第二次執行不會刪除或重建既有環境。
- 任一步驟失敗時回傳非零 exit code。
- 腳本不要求使用者先執行 `source .venv/bin/activate`。

### 步驟 5：建立 `download_db.sh`

預定執行流程：

1. 定位並確認 `config.sh` 存在。
2. 以 `source` 載入下載設定。
3. 檢查 `curl` 是否存在；若不存在則報錯並停止。
4. 確認目標資料夾存在且可寫入。
5. 在目標資料庫相同目錄建立暫存檔。
6. 使用 curl 下載：啟用 HTTP 錯誤失敗、redirect、安靜模式與錯誤輸出。
7. 驗證暫存檔存在且大小大於零。
8. 檢查回應不是 Google Drive 登入頁、確認頁或其他 HTML。
9. 檢查檔案具有 SQLite header。
10. 若系統存在 `sqlite3` 命令，再執行 `PRAGMA quick_check`。
11. 所有驗證通過後，以 `mv` 原子性替換 `DB_PATH`。
12. 無論成功或失敗都清理由本次建立的暫存檔。

建議 curl 行為：

- `--fail`
- `--location`
- `--show-error`
- `--silent`
- 可設定合理的連線及整體 timeout
- 可設定有限次數 retry，僅處理暫時性網路失敗

安全限制：

- 下載失敗不得破壞既有 `db.sqlite3`。
- 驗證失敗不得把 HTML 或空檔案當作資料庫。
- 不在每次應用程式啟動時無條件執行下載，避免覆蓋線上新增資料。

驗收條件：

- 有效 SQLite 檔能成功放到設定的 `DB_PATH`。
- HTTP 錯誤、空檔、HTML 回應或無效 SQLite 均回傳失敗。
- 若目標原先已有資料庫，失敗流程會保留原檔。
- 暫存檔不會在正常成功或已處理的失敗後殘留。

### 步驟 6：設定 Linux 執行權限

實作完成後，為三支腳本加入 executable bit：

```bash
chmod +x build_venv.sh config.sh download_db.sh
```

注意：`config.sh` 通常是被 `source`，技術上不必具備執行權限；為了三支腳本權限一致可選擇一併設定。Git 應記錄 executable mode，避免部署後仍需人工修正。

驗收條件：在 Linux clone 專案後可直接執行 `./build_venv.sh` 與 `./download_db.sh`。

### 步驟 7：執行靜態檢查

針對 Bash 腳本進行：

1. `bash -n config.sh`
2. `bash -n build_venv.sh`
3. `bash -n download_db.sh`
4. 若環境有 ShellCheck，再執行 `shellcheck` 檢查三支腳本。
5. 確認沒有 CRLF、Windows 指令或 Windows 路徑殘留。

驗收條件：三支腳本通過 `bash -n`；ShellCheck 不應有未處理的 error 級問題。

### 步驟 8：執行隔離式行為測試

測試時避免覆寫真正的 `.venv` 或 `db.sqlite3`：

1. 在暫存目錄或測試副本中執行。
2. 測試不存在與已存在 `.venv` 的兩條路徑。
3. 以測試環境變數覆寫 `DB_PATH`。
4. 測試缺少 curl、無效 URL、HTTP 失敗、HTML 回應及有效 SQLite。
5. 確認失敗時 exit code、錯誤訊息、既有 DB 保留情況。
6. 測試從其他 working directory 呼叫腳本。

驗收條件：所有成功與預期失敗情境均符合步驟 4、5 的驗收規則，且不更動正式資料庫。

### 步驟 9：檢查變更範圍並交付

1. 使用 Git status/diff 確認沒有改動主要程式碼。
2. 確認既有使用者變更沒有被覆寫或還原。
3. 記錄新增腳本、使用方式、必要 Linux 套件及測試結果。
4. 明確列出尚未處理的部署阻擋問題。

驗收條件：交付摘要能讓使用者清楚知道如何執行腳本、已驗證項目，以及仍需處理的事項。

## 4. 預定使用方式

完成實作後，預期 Linux 操作順序如下：

```bash
./build_venv.sh
./download_db.sh
```

若需覆寫預設資料庫位置，預期可用環境變數：

```bash
DB_PATH=/path/to/persistent/db.sqlite3 ./download_db.sh
```

此處只描述介面；本規劃階段尚未建立上述 `.sh` 檔案。

## 5. 不在本階段實作的事項

- 不修改 `DjangoBlog/settings.py` 的 `SECRET_KEY`、`DEBUG`、`ALLOWED_HOSTS` 或 static 設定。
- 不建立或修正 `article/urls.py`。
- 不新增 `user_login`、`user_logout` views。
- 不解決 `templates/base.html` 的 Git merge conflict。
- 不修改 models、migrations 或 SQLite schema。
- 不整併 `req.txt` 與 `requirement.txt`。
- 不加入 Gunicorn、Uvicorn、WhiteNoise 或 PostgreSQL。
- 不設定 systemd、Nginx、Docker 或 CI/CD。
- 不移除現有 Windows `.bat`。
- 不自動下載或覆蓋目前的 `db.sqlite3`。

## 6. 後續工作依賴與風險

即使三支 Bash 腳本全部完成，目前專案仍可能因下列既存問題無法正常部署：

1. Root URLconf 引用不存在的 `article.urls`。
2. Root URLconf 引用未定義的登入與登出 view。
3. `templates/base.html` 尚有 Git conflict markers。
4. 正式環境安全與 static files 設定不完整。
5. 兩份 Python 依賴清單不一致，且未包含 production application server。
6. SQLite 必須放在持久化、可寫入的單機磁碟；不適合多實例共享。
7. Google Drive 直連可能回傳確認頁而非資料庫，未來可能需要更可靠的備份儲存來源。

以上應在 Bash 腳本工作完成後，分成獨立任務處理與驗收。

## 7. 完成定義

後續實作階段需同時符合以下條件，才能視為完成：

- 三支 `.sh` 均已建立且保留原 `.bat`。
- 腳本使用安全、可攜的 Bash 語法與基於腳本位置的絕對路徑。
- 虛擬環境建立及重複執行行為正確。
- 資料庫使用暫存檔下載，經驗證後才替換正式檔案。
- 三支腳本通過 `bash -n`，並完成可行的行為測試。
- Git executable mode 與 LF 換行正確。
- Django 主要程式碼及使用者既有變更未被修改。
- 交付時清楚報告測試結果、限制及未完成的部署阻擋事項。

