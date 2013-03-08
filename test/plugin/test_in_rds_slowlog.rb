require 'helper'

class Rds_SlowlogInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag Rds_Slowlog
    aws_key_id test_key_id
    aws_sec_key test_sec_key
  ]

#  def test_configure
#    d = create_driver
#    assert_equal 'test_key_id', d.instance.aws_key_id
#    assert_equal 'test_sec_key', d.instance.aws_sec_key
#  end

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::Rds_SlowlogInput).configure(conf)
  end

end
