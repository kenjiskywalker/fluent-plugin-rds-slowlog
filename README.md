# fluent-plugin-rds-slowlog



## Overview
***AWS RDS slow_log*** input plugin.  

1. **"SELECT * FROM slow_log"**
2. **"CALL mysql.rds_rotate_slow_log"**

every 10 seconds from AWS RDS.

## Configuration

```config
<source>
  type rds_slowlog
  tag rds-slowlog
  host [RDS Hostname]
  username [RDS Username]
  password [RDS Password]
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

## TODO

* more test test test
