require 'mysql2'
require 'fluent/plugin/input'

class Fluent::Plugin::Rds_SlowlogInput < Fluent::Plugin::Input
  Fluent::Plugin.register_input("rds_slowlog", self)

  helpers :timer

  config_param :tag,          :string
  config_param :host,         :string,  :default => nil
  config_param :port,         :integer, :default => 3306
  config_param :username,     :string,  :default => nil
  config_param :password,     :string,  :default => nil, :secret => true
  config_param :interval,     :integer, :default => 10
  config_param :backup_table, :string,  :default => nil

  def initialize
    super
  end

  def configure(conf)
    super
    begin
      @client = create_mysql_client
    rescue
      log.error "fluent-plugin-rds-slowlog: cannot connect RDS"
    end
  end

  def start
    super
    if @backup_table
      @client.query("CREATE TABLE IF NOT EXISTS #{@backup_table} LIKE slow_log")
    end

    timer_execute(:in_rds_slowlog_timer, @interval, &method(:output))
  end

  def shutdown
    super
  end

  private
  def output
    @client.query('CALL mysql.rds_rotate_slow_log')

    slow_log_data = []
    slow_log_data = @client.query('SELECT * FROM slow_log_backup', :cast => false)

    slow_log_data.each do |row|
      row.each_key {|key| row[key].force_encoding(Encoding::ASCII_8BIT) if row[key].is_a?(String)}
      router.emit(tag, Fluent::Engine.now, row)
    end

    if @backup_table
      @client.query("INSERT INTO #{@backup_table} SELECT * FROM slow_log_backup")
    end
  rescue Mysql2::Error => e
    @log.error(e.message)
    @log.error_backtrace(e.backtrace)

    unless @client.ping
      @log.info('fluent-plugin-rds-slowlog: try to reconnect to RDS')
      @client = create_mysql_client
    end
  end

  def create_mysql_client
    Mysql2::Client.new({
      :host => @host,
      :port => @port,
      :username => @username,
      :password => @password,
      :database => 'mysql'
    })
  end
end
