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

      client.query <<-EOS
        CREATE PROCEDURE `mysql`.`rds_rotate_slow_log`()
        BEGIN
          DECLARE sql_logging BOOLEAN;
          select @@sql_log_bin into sql_logging;
          set @@sql_log_bin=off;
          CREATE TABLE IF NOT EXISTS mysql.slow_log2 LIKE mysql.slow_log;

          INSERT INTO `mysql`.`slow_log2` (
            `start_time`, `user_host`, `query_time`, `lock_time`, `rows_sent`, `rows_examined`, `db`, `last_insert_id`, `insert_id`, `server_id`, `sql_text`)
          VALUES
            ('2015-09-29 15:43:44', 'root@localhost', '00:00:00', '00:00:00', 0, 0, 'employees', 0, 0, 1, 'SELECT 1')
           ,('2015-09-29 15:43:45', 'root@localhost', '00:00:00', '00:00:00', 0, 0, 'employees', 0, 0, 1, 'SELECT 2')
          ;

          DROP TABLE IF EXISTS mysql.slow_log_backup;
          RENAME TABLE mysql.slow_log TO mysql.slow_log_backup, mysql.slow_log2 TO mysql.slow_log;
          set @@sql_log_bin=sql_logging;
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
    records = d.emits

    # for Travis CI
    records.each {|r| r[2].delete("thread_id") }

    assert_equal [
      ["rds-slowlog", 1432492200, {"start_time"=>"2015-09-29 15:43:44", "user_host"=>"root@localhost", "query_time"=>"00:00:00", "lock_time"=>"00:00:00", "rows_sent"=>"0", "rows_examined"=>"0", "db"=>"employees", "last_insert_id"=>"0", "insert_id"=>"0", "server_id"=>"1", "sql_text"=>"SELECT 1"}],
      ["rds-slowlog", 1432492200, {"start_time"=>"2015-09-29 15:43:45", "user_host"=>"root@localhost", "query_time"=>"00:00:00", "lock_time"=>"00:00:00", "rows_sent"=>"0", "rows_examined"=>"0", "db"=>"employees", "last_insert_id"=>"0", "insert_id"=>"0", "server_id"=>"1", "sql_text"=>"SELECT 2"}],
    ], records
  end
end
