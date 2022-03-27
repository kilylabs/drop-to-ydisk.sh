# drop-to-ydisk.sh
Shell-скрипт для синхронизации Dropbox с Яндекс.Диск без необходимости хранения промежуточных файлов (на самом деле немного места нужно 😊).

Скрипт написан с использованием библиотек:
- https://github.com/andreafabrizi/Dropbox-Uploader (для скачивания файлов из Dropbox)
- https://github.com/abbat/ydcmd (для загрузки файлов в Яндекс.Диск)

## Пример использования

```shell
# git clone https://github.com/kilylabs/drop-to-ydisk.sh.git drop-to-ydisk
# cd drop-to-ydisk
# chmod +x ./drop-to-ydisk.sh
# ./drop-to-ydisk.sh install
....
# ./drop-to-ydisk.sh MyDropboxFolder
YDCMD: Creating dir MyDropboxFolder
DROPBOX:  > Downloading "/MyDropboxFolder/file.xlsx" to "_tmp/file.xlsx"... DONE
YDCMD: Uploading file file.xlsx to MyDropboxFolder/file.xlsx
LOCAL: Removing uploaded file _tmp/file.xlsx
#
```
