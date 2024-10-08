# 使用方法
使用前必須安裝docker和angular\
放在和前後端一個目錄ex:
![img.png](img.png)
* docker_packer是全部都丟上docker
* docker_update能選擇丟哪個
# 可能會出現的error
```
'mvn' 不是內部或外部命令、可執行的程式或批次檔。
```
安裝maven後再次執行.bat就不會有\
或使用ide附的maven先跑一次
```
mvn clean install
```
不然你的檔案放上docker後會是舊的