#!/bin/bash
# Задаем переменные:
TIME=`date +»%Y-%m-%d_%H-%M»`

# Записываем информацию о начале бэкапа в лог:
echo «`date +»%Y-%m-%d_%H-%M-%S»` Start backup» >> /mnt/backup/PgSql/pgsql-everyday-backup.log

# Бэкапим и архивируем. При бэкапе еще одной базы — копируем эту команду с заменой имени базы с учетом регистра.
pg_dump -U postgres bueks | pigz > /mnt/backup/PgSql/everyday/bueks/$TIME-bueks.sql.gz
pg_dump -U postgres butmt | pigz > /mnt/backup/PgSql/everyday/butmt/$TIME-butmt.sql.gz
pg_dump -U postgres buvfn | pigz > /mnt/backup/PgSql/everyday/buvfn/$TIME-buvfn.sql.gz

# Записываем информацию о завершении бэкапа в лог:
echo «`date +»%Y-%m-%d_%H-%M-%S»` End backup» >> /mnt/backup/PgSql/pgsql-everyday-backup.log

# Удаляем файлы старше 60 дней с локального диска
find /mnt/backup/PgSql/everyday -type f -mtime +60 -exec rm -rf {} \;
