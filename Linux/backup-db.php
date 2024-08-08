<?php
// 数据库配置
$dbHost = 'mysql0.serv00.com';  // 数据库主机名
$dbUser = 'm6095_alist';  // 数据库用户名
$dbPass = 'cc7a+M9-w19]0eW1y05iDEI2pMO0D(';  // 数据库密码
$dbName = 'm6095_alist';  // 要备份的数据库名

// 备份目录
$backupDir = __DIR__ . '/backups/';   // 备份文件存储目录

// 日志文件路径
$logFile = __DIR__ . '/backups/backup_log.txt'; // 日志文件路径

// 创建备份目录（如果不存在）
if (!file_exists($backupDir)) {
    mkdir($backupDir, 0755, true);
}

// 备份文件名（以当前日期和时间为文件名）
$backupFile = $backupDir . $dbName . '_' . date('Y-m-d_H-i-s') . '.sql';

// 构建 mysqldump 命令
$command = sprintf(
    'mysqldump --no-tablespaces -u%s -p%s -h%s %s > %s',
    escapeshellarg($dbUser),
    escapeshellarg($dbPass),
    escapeshellarg($dbHost),
    escapeshellarg($dbName),
    escapeshellarg($backupFile)
);

// 执行备份命令
exec($command, $output, $returnValue);

// 写入日志
$logMessage = date('Y-m-d H:i:s') . " - ";
if ($returnValue === 0) {
    $logMessage .= "Database backup successfully! Backup files are stored in: $backupFile";
} else {
    $logMessage .= "Database backup failed! Error: " . implode("\n", $output);
}

// 将日志信息写入日志文件
file_put_contents($logFile, $logMessage . PHP_EOL, FILE_APPEND);

// 删除超过30个备份文件
$backupFiles = glob($backupDir . $dbName . '_*.sql');
$backupCount = count($backupFiles);

if ($backupCount > 30) {
    // 对备份文件按照修改时间进行排序
    usort($backupFiles, function ($a, $b) {
        return filemtime($a) < filemtime($b);
    });

    // 删除超过30个的备份文件
    for ($i = 30; $i < $backupCount; $i++) {
        if (unlink($backupFiles[$i])) {
            $deleteLogMessage = date('Y-m-d H:i:s') . " - Deleted backup file: {$backupFiles[$i]}";
            file_put_contents($logFile, $deleteLogMessage . PHP_EOL, FILE_APPEND);
        } else {
            $deleteLogMessage = date('Y-m-d H:i:s') . " - Failed to delete backup file: {$backupFiles[$i]}";
            file_put_contents($logFile, $deleteLogMessage . PHP_EOL, FILE_APPEND);
        }
    }
}
?>