require 'helper'

class RdsSlowlogWithSdkInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag                    rds-slowlog-with-sdk
    aws_access_key_id      access_key
    aws_secret_access_key  secret_key
    aws_rds_region         ap-northeast-1
    db_instance_identifier some-rds-instance
    log_file_name          slowquery/mysql-slowquery.log
    timezone               Asia/Tokyo
    offset                 +09:00
    duration_sec           10
    pos_file               /path/to/file
    sns_topic_arn          arn:aws:sns:ap-northeast-1:xx
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::RdsSlowlogWithSdkInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'rds-slowlog-with-sdk',          d.instance.tag
    assert_equal 'access_key',                    d.instance.aws_access_key_id
    assert_equal 'secret_key',                    d.instance.aws_secret_access_key
    assert_equal 'ap-northeast-1',                d.instance.aws_rds_region
    assert_equal 'some-rds-instance',             d.instance.db_instance_identifier
    assert_equal 'slowquery/mysql-slowquery.log', d.instance.log_file_name
    assert_equal 'Asia/Tokyo',                    d.instance.timezone
    assert_equal '+09:00',                        d.instance.offset
    assert_equal 10,                              d.instance.duration_sec
    assert_equal '/path/to/file',                 d.instance.pos_file
    assert_equal 'arn:aws:sns:ap-northeast-1:xx', d.instance.sns_topic_arn
  end

end
