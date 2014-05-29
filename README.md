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
  tag                    [Unique tag for RDS Instance]
  aws_access_key_id      [RDS Access Key]
  aws_secret_access_key  [RDS Secret Key]
  aws_rds_region         [RDS Region]
  db_instance_identifier [RDS Instance Identifier]
  log_file_name          [RDS Slow Log File Name]
  timezone               [Timezone Where RDS Region Exists]
  offset                 [Offset From UTC]
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
  aws_rds_region         ap-northeast-1
  db_instance_identifier my-rds-server
  log_file_name          slowquery/mysql-slowquery.log
  timezone               Asia/Tokyo
  offset                 +09:00
  duration_sec           10
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

Format

```
slow_query_date	tag	record_json
```

Example

```
2014-05-29T16:20:04+09:00	rds-slowlog-with-sdk	{"user":"infra[infra]","host":"ip-10-146-157-87.ap-northeast-1.compute.internal","host_ip":"10.146.157.87","query_time":2.007943,"lock_time":0.0,"rows_sent":1,"rows_examined":0,"date":"2014-05-29 16:20:04 +09:00","sql":"SET timestamp=1401348004; select sleep(2);","timezone":"Asia/Tokyo","offset":"+09:00"}
2014-05-29T16:20:04+09:00	rds-slowlog-with-sdk	{"user":"infra[infra]","host":"ip-10-146-157-87.ap-northeast-1.compute.internal","host_ip":"10.146.157.87","query_time":2.009605,"lock_time":0.0,"rows_sent":1,"rows_examined":0,"date":"2014-05-29 16:20:04 +09:00","sql":"SET timestamp=1401348004; select sleep(2);","timezone":"Asia/Tokyo","offset":"+09:00"}
```

#### if not connect

- td-agent.log

```
2013-06-29 00:32:55 +0900 [error]: fluent-plugin-rds-slowlog-with-sdk: cannot connect RDS
```

