# fluent-plugin-rds-slowlog [![Build Status](https://travis-ci.org/kenjiskywalker/fluent-plugin-rds-slowlog.png)](https://travis-ci.org/kenjiskywalker/fluent-plugin-rds-slowlog/)


## RDS Setting

[Working with MySQL Database Log Files / aws documentation](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.MySQL.html)

- Set the `slow_query_log` parameter to `1`
- setting `min_examined_row_limit`
- setting `long_query_time`

## Overview
***AWS RDS slow_log*** input plugin.

1. **"CALL mysql.rds_rotate_slow_log"**
2. **"SELECT * FROM slow_log_backup"**
3. **"INSERT INTO yourdb.slow_log_custom_backup SELECT * FROM slow_log_backup"** (if you want to take a backup)

every 10 seconds from AWS RDS.

## Configuration

```config
<source>
  type rds_slowlog
  tag rds-slowlog
  host [RDS Hostname]
  username [RDS Username]
  password [RDS Password]
  custom_table [Your Backup Tablename]
</source>
```

### Example GET RDS slow_log

```config
<source>
  type rds_slowlog
  tag rds-slowlog
  host [RDS Hostname]
  username [RDS Username]
  password [RDS Password]
  interval 10
  custom_table [Your Backup Tablename]
</source>

<match rds-slowlog>
  type copy
 <store>
  type file
  path /var/log/slow_log
 </store>
</match>
```

#### output data format

```
2013-03-08T16:04:43+09:00       rds-slowlog     {"start_time":"2013-03-08 07:04:38","user_host":"rds_db[rds_db] @  [192.0.2.10]","query_time":"00:00:00","lock_time":"00:00:00","rows_sent":"3000","rows_examined":"3000","db":"rds_db","last_insert_id":"0","insert_id":"0","server_id":"100000000","sql_text":"select foo from bar"}
2013-03-08T16:04:43+09:00       rds-slowlog     {"start_time":"2013-03-08 07:04:38","user_host":"rds_db[rds_db] @  [192.0.2.10]","query_time":"00:00:00","lock_time":"00:00:00","rows_sent":"3000","rows_examined":"3000","db":"rds_db","last_insert_id":"0","insert_id":"0","server_id":"100000000","sql_text":"Quit"}
```

#### if not connect

- td-agent.log

```
2013-06-29 00:32:55 +0900 [error]: fluent-plugin-rds-slowlog: cannot connect RDS
```

