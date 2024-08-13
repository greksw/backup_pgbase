#!/bin/bash
# Задаем переменные:
TIME=`date +"%Y-%m-%d_%H-%M"`

# Пути к лог-файлу и точкам монтирования
LOG_FILE="/mnt/pgsql.log"
MOUNT_POINT1="/mnt/backup/PgSql"

# Telegram Bot API параметры
TOKEN="22222222:111111111eejccLggbvO22222222"
CHAT_ID="111111111"

# Название скрипта для уведомлений
SCRIPT_NAME="Резервное копирование 1c8c_PG_everyday:"

# Функция для записи логов и отправки уведомлений
log_and_notify() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> $LOG_FILE
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id=$CHAT_ID -d text="$SCRIPT_NAME: $message" > /dev/null
}

# Функция для выполнения pg_dump и отправки статуса
backup_and_notify() {
    local dbname="$1"
    local output_path="$2"
    pg_dump -U postgres $dbname | pigz > $output_path
    if [ $? -eq 0 ]; then
        log_and_notify "✅ База данных $dbname успешно скопирована."
    else
        log_and_notify "❌ Ошибка при копировании базы данных $dbname."
    fi
}

# IP адреса компьютеров
HOST1="192.168.1.2"

# Проверка доступности хостов
ping -c 1 $HOST1 > /dev/null 2>&1
HOST1_STATUS=$?

# Если хост доступен
if [ $HOST1_STATUS -eq 0 ]; then
    log_and_notify "✅ Хост доступен, монтируем шары..."

    # Монтируем шары
    sudo mount -t cifs //192.168.1.2/Backup_data/PgSql $MOUNT_POINT1 -o username=user1,password=123,domain=workgroup,iocharset=utf8,file_mode=0777,dir_mode=0777
    MOUNT1_STATUS=$?

    # Если монтирование прошло успешно
    if [ $MOUNT1_STATUS -eq 0 ]; then
        log_and_notify "✅ Шара успешно примонтирована, выполняем pgbackup script..."

        # Выполняем бэкап и проверяем статус
        backup_and_notify "bueks" "/mnt/backup/PgSql/everyday/bueks/$TIME-bueks.sql.gz"
        backup_and_notify "butmt" "/mnt/backup/PgSql/everyday/butmt/$TIME-butmt.sql.gz"
        backup_and_notify "buvfn" "/mnt/backup/PgSql/everyday/buvfn/$TIME-buvfn.sql.gz"

        # Записываем информацию о завершении бэкапа в лог:
        echo "`date +'%Y-%m-%d_%H-%M-%S'` End backup" >> /mnt/backup/PgSql/pgsql-everyday-backup.log

        # Удаляем файлы старше 60 дней с локального диска
        find /mnt/backup/PgSql/everyday -type f -mtime +60 -exec rm -rf {} \;

        # Размонтируем шары
        log_and_notify "🔄 Выполняем отмонтирование..."
        sudo umount $MOUNT_POINT1
        log_and_notify "✅ Шара успешно отмонтирована."
    else
        log_and_notify "❌ Не удалось примонтировать шару."

        # Попытка размонтирования в случае частичного монтирования
        if mount | grep $MOUNT_POINT1 > /dev/null; then
            sudo umount $MOUNT_POINT1
        fi
    fi
else
    log_and_notify "❌ Хост недоступен."
fi
