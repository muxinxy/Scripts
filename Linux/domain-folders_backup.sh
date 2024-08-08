#!/bin/bash

backup_domains() {
    if [ ! -f "$DOMAINS_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 域名列表文件不存在: $DOMAINS_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi
    while IFS= read -r domain; do
        BACKUP_FILE="$BACKUPS_DIR/$(date +%Y-%m-%d_%H-%M)-${domain}.tar.gz"
        if tar -czf "$BACKUP_FILE" "$DOMAINS_DIR/${domain}/"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 成功打包: $BACKUP_FILE" | tee -a "$LOG_FILE"
            echo "$BACKUP_FILE" >> $BACKUPS_DIR/backups.txt
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 打包失败: $BACKUP_FILE" | tee -a "$LOG_FILE"
        fi
    done < "$DOMAINS_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 所有域名目录打包完成。" | tee -a "$LOG_FILE"
}

upload_backups() {
    if [ ! -f "$DOMAINS_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 域名列表文件不存在: $DOMAINS_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi
    while IFS= read -r backup_file; do
        HTTP_RESPONSE_CODE=$(curl -u "$USERNAME:$PASSWORD" -T "$backup_file" -s -w "%{http_code}" "$WEBDAV_URL/$(basename $backup_file)")
        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 上传成功: $backup_file" | tee -a "$LOG_FILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 上传失败: $backup_file" | tee -a "$LOG_FILE"
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - HTTP 响应代码: $HTTP_RESPONSE_CODE" | tee -a "$LOG_FILE"
    done < "$BACKUPS_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 所有域名打包文件上传完成。" | tee -a "$LOG_FILE"
}

delete_old_backups() {
    if [ ! -f "$DOMAINS_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 域名列表文件不存在: $DOMAINS_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 域名数量
    DOMAINS_NUM=$(wc -l $DOMAINS_FILE | awk '{print $1}')
    # 保留的文件数量
    RES_NUM=$((${DOMAINS_NUM}*$NUMBER))
    echo "保留的文件数量 RES_NUM=DOMAINS_NUM*NUMBER=${DOMAINS_NUM}*$NUMBER=$RES_NUM" | tee -a "$LOG_FILE"

    while IFS= read -r domain; do
        find "$BACKUPS_DIR" -type f -name "*-${domain}.tar.gz" -exec ls -lt {} + | awk 'NR>'$NUMBER' {print $9}' | while read -r file; do
            if rm "$file"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - 删除成功: $file" | tee -a "$LOG_FILE"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - 删除失败: $file" | tee -a "$LOG_FILE"
            fi
        done
    done < "$DOMAINS_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 本地域名备份文件保留最近$NUMBER个完成。" | tee -a "$LOG_FILE"
}

delete_webdav_files() {
    if [ ! -f "$DOMAINS_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 域名列表文件不存在: $DOMAINS_FILE" | tee -a "$LOG_FILE"
        exit 1
    fi

    # 域名数量
    DOMAINS_NUM=$(wc -l $DOMAINS_FILE | awk '{print $1}')
    # 保留的文件数量
    RES_NUM=$((${DOMAINS_NUM}*$NUMBER))
    echo "保留的文件数量 RES_NUM=DOMAINS_NUM*NUMBER=${DOMAINS_NUM}*$NUMBER=$RES_NUM" | tee -a "$LOG_FILE"

    curl -X PROPFIND -u "$USERNAME:$PASSWORD" -o "$XML_FILE" "$WEBDAV_URL/"
    file_names=$(awk 'BEGIN{RS="<D:displayname>|</D:displayname>";ORS="\n"}NR%2==0' "$XML_FILE" | tail -n +2)
    sorted_file_names=$(echo "$file_names" | sort -r)
    for file_name in $sorted_file_names; do
        echo $file_name
    done
    later_file_names=$(echo "$sorted_file_names" | tail -n +$(($RES_NUM+ 1)))
    for file_name in $later_file_names; do
        HTTP_RESPONSE_CODE=$(curl -X DELETE -u "$USERNAME:$PASSWORD" -s -o /dev/null -w "%{http_code}" "${WEBDAV_URL}/${file_name}")
        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 远程删除成功: ${file_name}" | tee -a "$LOG_FILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 远程删除失败: ${file_name}" | tee -a "$LOG_FILE"
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - HTTP 响应代码: $HTTP_RESPONSE_CODE" | tee -a "$LOG_FILE"
    done
    #rm -f "$XML_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 远程域名备份文件保留最近$NUMBER个完成。" | tee -a "$LOG_FILE"
}

# 检查参数数量
if [ $# -ne 7 ]; then
    echo "Error: Missing some required parameters."
    echo "Usage: $(basename $0) DOMAINS_FILE BACKUPS_DIR DOMAINS_DIR WEBDAV_URL USERNAME PASSWORD NUMBER"
    exit 1
fi

# 按顺序解析参数
DOMAINS_FILE=$1
BACKUPS_DIR=$2
DOMAINS_DIR=$3
WEBDAV_URL=$4
USERNAME=$5
PASSWORD=$6
NUMBER=$7
LOG_FILE="$BACKUPS_DIR/backups.log"
XML_FILE="$BACKUPS_DIR/backups.xml"
BACKUPS_FILE="$BACKUPS_DIR/backups.txt"

# 检查文件是否存在
if [ ! -f "$DOMAINS_FILE" ]; then
     echo "$(date '+%Y-%m-%d %H:%M:%S') - 域名列表文件不存在: $DOMAINS_FILE" | tee -a "$LOG_FILE"
     exit 1
fi

if [ -f "$BACKUPS_FILE" ]; then
     rm $BACKUPS_FILE
fi

if [ -f "$XML_FILE" ]; then
     rm $XML_FILE
fi

# 按顺序执行函数
backup_domains
upload_backups
delete_old_backups
delete_webdav_files