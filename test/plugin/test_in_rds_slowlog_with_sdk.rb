require 'helper'

class RdsSlowlogWithSdkInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag rds-slowlog-with-sdk
    host localhost
    username test_rds_user
    password test_rds_password
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::RdsSlowlogWithSdkInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'rds-slowlog-with-sdk', d.instance.tag
    assert_equal 'localhost', d.instance.host
    assert_equal 'test_rds_user', d.instance.username
    assert_equal 'test_rds_password', d.instance.password
  end

end
