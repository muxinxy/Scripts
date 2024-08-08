@echo off
setlocal

rem 第一个 rclone sync 命令
start "" cmd /c "rclone sync e5:Crypt 189:Crypt -P --header "Referer:" --buffer-size=256M --use-mmap -v --transfers 2 --timeout 10m --exclude *lOwxX0s3AqGhxjP*"

rem 第二个 rclone sync 命令
start "" cmd /c "rclone sync e5:Crypt al:Crypt -P --header "Referer:" --buffer-size=256M --use-mmap -v --transfers 2 --timeout 10m"

rem 等待所有窗口完成
wait

endlocal
