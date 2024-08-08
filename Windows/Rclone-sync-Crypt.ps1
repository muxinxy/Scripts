# 保存当前的变量状态
Set-StrictMode -Version Latest

# 第一个 rclone sync 命令
$process1 = Start-Process -FilePath "rclone" -ArgumentList "sync e5:Crypt 189:Crypt -P --header 'Referer:' --buffer-size=256M --use-mmap -v --transfers 2 --timeout 10m --exclude *lOwxX0s3AqGhxjP*" -NoNewWindow -PassThru

# 第二个 rclone sync 命令
$process2 = Start-Process -FilePath "rclone" -ArgumentList "sync e5:Crypt al:Crypt -P --header 'Referer:' --buffer-size=256M --use-mmap -v --transfers 2 --timeout 10m" -NoNewWindow -PassThru

# 等待所有进程完成
Wait-Process -Id $process1.Id
Wait-Process -Id $process2.Id
