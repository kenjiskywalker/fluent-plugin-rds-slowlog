# fluent-plugin-rds-slowlog-with-sdk [![Build Status](https://travis-ci.org/ando-masaki/fluent-plugin-rds-slowlog-with-sdk.svg)](https://travis-ci.org/ando-masaki/fluent-plugin-rds-slowlog-with-sdk)


## RDS Setting

[Working with MySQL Database Log Files / aws documentation](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.MySQL.html)

- Set the `slow_query_log` parameter to `1`
- setting `min_examined_row_limit`
- setting `long_query_time`

## Overview
***AWS RDS slow_log with SDK*** input plugin.  

1. **Call API AWS RDS Client DownloadDbLogFilePortion with marker**

every 10 seconds from AWS RDS.

## Configuration

```config
<source>
  type                   rds_slowlog_with_sdk
  tag                    rds-slowlog-with-sdk
  aws_access_key_id      [RDS Access Key]
  aws_secret_access_key  [RDS Secret Key]
  aws_rds_region         [RDS Region]
  db_instance_identifier [RDS Instance Identifier]
  log_file_name          [RDS Slow Log File Name]
  offset_time            [Offset From UTC]
  duration_sec           [Duration Seconds To Watch Slow Log File]
</source>
```

### Example GET RDS slow_log

```config
<source>
  type                   rds_slowlog_with_sdk
  tag                    rds-slowlog-with-sdk
  aws_access_key_id      [RDS Access Key]
  aws_secret_access_key  [RDS Secret Key]
  aws_rds_region         [RDS Region]
  db_instance_identifier [RDS Instance Identifier]
  log_file_name          [RDS Slow Log File Name]
  offset_time            [Offset From UTC]
  duration_sec           [Duration Seconds To Watch Slow Log File]
</source>

<match rds-slowlog-with-sdk>
  type copy
 <store>
  type file
  path /var/log/slow_log
 </store>
</match>
```

#### output data format

```
2013-03-08T16:04:43+09:00       rds-slowlog-with-sdk     {"start_time":"2013-03-08 07:04:38","user_host":"rds_db[rds_db] @  [192.0.2.10]","query_time":"00:00:00","lock_time":"00:00:00","rows_sent":"3000","rows_examined":"3000","db":"rds_db","last_insert_id":"0","insert_id":"0","server_id":"100000000","sql_text":"select foo from bar"}
2013-03-08T16:04:43+09:00       rds-slowlog-with-sdk     {"start_time":"2013-03-08 07:04:38","user_host":"rds_db[rds_db] @  [192.0.2.10]","query_time":"00:00:00","lock_time":"00:00:00","rows_sent":"3000","rows_examined":"3000","db":"rds_db","last_insert_id":"0","insert_id":"0","server_id":"100000000","sql_text":"Quit"}
```

#### if not connect

- td-agent.log

```
2013-06-29 00:32:55 +0900 [error]: fluent-plugin-rds-slowlog-with-sdk: cannot connect RDS
```

