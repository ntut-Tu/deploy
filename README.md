# 編譯與部署

三個 repository 放在同一層：

```text
workspace/
├── cloth_shop_server/
├── cloth_shop_web/
└── deploy/
```

前提：Java 17（JAVA_HOME 指向 JDK，或 PATH 有 java）、已啟動且目前使用者有權存取的 Docker Engine、Docker Compose v2 或以上（支援 `up --wait-timeout`）、可下載 Maven/npm 套件與容器映像的網路。前端由容器內 Node 20 建置，不需主機安裝 Node、npm 或 Angular CLI。不需預先建立任何專案 container、DB、資料表、資料或產碼結果。

## 從原始碼一鍵部署

```sh
sh deploy/deploy.sh
```

亦可從任何目錄呼叫腳本的絕對路徑。腳本先執行後端 `mvnw clean package`，再建置前後端映像，最後等待 PostgreSQL、後端、前端健康。成功時列出網站網址，預設為 http://localhost:80。任何建置／測試／健康檢查失敗都回傳非零，停止後續步驟並保留 DB 資料供檢查。

原有所有開發／首次／更新 BAT 入口統一由 `deploy.sh` 取代，不再需要 H2 首次編譯或互動選單。`image_deploy.sh` 取代原映像載入 BAT。

## 單獨編譯後端

```sh
cd cloth_shop_server
./mvnw clean package
```

Maven 自動啟動暫時 PostgreSQL，執行 Liquibase migration 與既有初始資料，生成 jOOQ，再關閉產碼 DB。測試另建隔離 DB。編譯輸出 `target/clothing-shop.jar`，不連部署 DB。不要先執行 Compose 或手動匯入 SQL。

## 資料保存與設定

正式服務使用 `database-data` 與 `product-images` 具名 volumes。再次執行 `deploy.sh` 保留資料，Liquibase 只套用尚未執行的 migration。正常更新不需 `down`，更不可使用 `down --volumes` 清除資料。

可選環境變數：`FRONTEND_PORT`（80）、`BACKEND_PORT`（8080）、`DATABASE_PORT`（5433）、`DEBUG_PORT`（5005）、`POSTGRES_PASSWORD`（123，延續既有開發預設）。前端 API 使用目前網站 origin，包含自訂埠。PostgreSQL 建置、測試與部署均使用 `postgres:16-alpine`。既有 volume 的密碼不會因修改環境變數而自動變更。

這是從零建立與後續更新的部署流程。舊版使用 `postgres:latest` 且未掛載明確 DB volume 的資料，不會自動搬進新 volume；若有舊版資料需另行規劃備份還原，勿直接刪除舊容器。

## 從已匯出的映像部署

將本版建置的 `frontend-image.tar`、`backend-image.tar` 及含有 `postgres:16-alpine` tag 的 `postgres.tar` 放入 `deploy/images/`，執行：

```sh
sh deploy/image_deploy.sh
```

此入口只載入映像並啟動服務，不編譯原始碼，因此不要求 Java。若從零開始且沒有映像，請使用 `deploy.sh`。

## 自動測試

```sh
sh deploy/tests/deploy-test.sh
sh deploy/tests/smoke.sh
```

第一個是 12 個 Shell 單元測試，以 fake external commands 驗證真實腳本的呼叫順序、路徑空白、失败傳遞與成功訊息。第二個需要真實 Docker 與 curl，使用獨立 Compose project／隨機主機埠，執行兩次完整部署，驗證 API、DB 與上傳資料保存。僅刪除測試自行建立的 project 與 volumes，不清除其他環境。

Jenkins agent 需 Java 17 與 Docker 存取能力，後端建置命令同上，無需 DB service 或 bootstrap job。若 agent 本身是容器，還需正確的 Docker socket、掛載路徑與容器映射埠路由，參考 [Testcontainers CI 文件](https://java.testcontainers.org/supported_docker_environment/continuous_integration/dind_patterns/)。部署時需取得三個相鄰 repos 與 Compose v2。
