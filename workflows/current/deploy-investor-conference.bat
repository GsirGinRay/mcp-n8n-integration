@echo off
echo ================================
echo  法説會自動化系統部署腳本
echo ================================
echo.

echo [1/6] 檢查 Node.js 環境...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js 未安裝，請先安裝 Node.js
    pause
    exit /b 1
) else (
    echo ✅ Node.js 環境正常
)

echo.
echo [2/6] 安裝必要的 npm 套件...
npm install n8n-nodes-supabase puppeteer cheerio @supabase/supabase-js
if errorlevel 1 (
    echo ❌ npm 套件安裝失敗
    pause
    exit /b 1
) else (
    echo ✅ npm 套件安裝成功
)

echo.
echo [3/6] 複製環境變數檔案...
if not exist ".env" (
    copy "workflows\current\supabase-config.env" ".env"
    echo ✅ .env 檔案已創建，請編輯填入您的 Supabase 配置
    echo.
    echo ⚠️  重要：請編輯 .env 檔案並填入以下資訊：
    echo    - SUPABASE_URL
    echo    - SUPABASE_SERVICE_KEY  
    echo    - SLACK_WEBHOOK_URL (可選)
    echo.
    pause
) else (
    echo ⚠️  .env 檔案已存在，請確認配置正確
)

echo.
echo [4/6] 檢查 Supabase 連接...
echo 請確認您已在 Supabase 中執行了以下 SQL 檔案：
echo - workflows/current/investor-conference-schema.sql
echo - workflows/current/supabase-functions.sql
echo.
echo 按任意鍵繼續...
pause >nul

echo.
echo [5/6] 啟動 n8n...
echo n8n 將在 http://localhost:5678 啟動
echo 請匯入工作流程檔案：workflows/current/investor-conference-workflow.json
echo.
echo 按 Ctrl+C 停止 n8n
echo.
start /b n8n start

echo.
echo [6/6] 部署完成！
echo.
echo 📋 後續步驟：
echo 1. 開啟瀏覽器訪問 http://localhost:5678
echo 2. 匯入工作流程：workflows/current/investor-conference-workflow.json
echo 3. 配置 Supabase 連接資訊
echo 4. 測試工作流程
echo 5. 設定定時執行
echo.
echo 📚 參考文件：
echo - 實作指南：workflows/current/n8n-implementation-guide.md
echo - 測試指南：workflows/current/testing-optimization-guide.md
echo.
echo 🎉 祝您使用愉快！
echo.
pause