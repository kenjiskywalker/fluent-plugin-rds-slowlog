require 'helper'

class Rds_SlowlogInputTest < Test::Unit::TestCase
  class << self
    def startup
      setup_database
      Timecop.freeze(Time.parse('2015/05/24 18:30 UTC'))
    end

    def shutdown
      cleanup_database
    end

    def setup_database
      client = Mysql2::Client.new(:username => 'root')
      client.query("GRANT ALL ON *.* TO test_rds_user@localhost IDENTIFIED BY 'test_rds_password'")
      client.query("DROP TABLE IF EXISTS `mysql`.`slow_log`")

      client.query <<-EOS
        CREATE TABLE `mysql`.`slow_log` (
          `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          `user_host` mediumtext NOT NULL,
          `query_time` time NOT NULL,
          `lock_time` time NOT NULL,
          `rows_sent` int(11) NOT NULL,
          `rows_examined` int(11) NOT NULL,
          `db` varchar(512) NOT NULL,
          `last_insert_id` int(11) NOT NULL,
          `insert_id` int(11) NOT NULL,
          `server_id` int(10) unsigned NOT NULL,
          `sql_text` mediumtext NOT NULL,
          `thread_id` bigint(21) unsigned NOT NULL
        ) ENGINE=CSV DEFAULT CHARSET=utf8 COMMENT='Slow log'
      EOS

      client.query <<-EOS
        CREATE PROCEDURE `mysql`.`rds_rotate_slow_log`()
        BEGIN
          CREATE TABLE IF NOT EXISTS mysql.slow_log2 LIKE mysql.slow_log;

          INSERT INTO `mysql`.`slow_log2` VALUES
            ('2015-09-29 15:43:44', 'root@localhost', '00:00:00', '00:00:00', 0, 0, 'employees', 0, 0, 1, 'SELECT 1', 10)
           ,('2015-09-29 15:43:45', 'root@localhost', '00:00:00', '00:00:00', 0, 0, 'employees', 0, 0, 1, 'SELECT 2', 11)
          ;

          DROP TABLE IF EXISTS mysql.slow_log_backup;
          RENAME TABLE mysql.slow_log TO mysql.slow_log_backup, mysql.slow_log2 TO mysql.slow_log;
        END
      EOS
    end

    def cleanup_database
      client = Mysql2::Client.new(:username => 'root')
      client.query("DROP USER test_rds_user@localhost")
      client.query("DROP PROCEDURE `mysql`.`rds_rotate_slow_log`")
    end
  end

  def rotate_slow_log
    client = Mysql2::Client.new(:username => 'root')
    client.query("CALL `mysql`.`rds_rotate_slow_log`")
  end

  def setup
    Fluent::Test.setup
    rotate_slow_log
  end

  CONFIG = %[
    tag rds-slowlog
    host localhost
    username test_rds_user
    password test_rds_password
    interval 0
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::Rds_SlowlogInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'rds-slowlog', d.instance.tag
    assert_equal 'localhost', d.instance.host
    assert_equal 'test_rds_user', d.instance.username
    assert_equal 'test_rds_password', d.instance.password
    assert_equal 0, d.instance.interval
  end

  def test_output
    d = create_driver
    d.run

    assert_equal [
      ["rds-slowlog", 1432492200, {"start_time"=>"2015-09-29 15:43:44", "user_host"=>"root@localhost", "query_time"=>"00:00:00", "lock_time"=>"00:00:00", "rows_sent"=>"0", "rows_examined"=>"0", "db"=>"employees", "last_insert_id"=>"0", "insert_id"=>"0", "server_id"=>"1", "sql_text"=>"SELECT 1", "thread_id"=>"10"}],
      ["rds-slowlog", 1432492200, {"start_time"=>"2015-09-29 15:43:45", "user_host"=>"root@localhost", "query_time"=>"00:00:00", "lock_time"=>"00:00:00", "rows_sent"=>"0", "rows_examined"=>"0", "db"=>"employees", "last_insert_id"=>"0", "insert_id"=>"0", "server_id"=>"1", "sql_text"=>"SELECT 2", "thread_id"=>"11"}],
    ], d.emits
  end
end
