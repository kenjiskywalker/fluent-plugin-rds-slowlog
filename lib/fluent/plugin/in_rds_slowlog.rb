class Fluent::Rds_SlowlogInput < Fluent::Input
  Fluent::Plugin.register_input("rds_slowlog", self)

  config_param :tag,      :string
  config_param :host,     :string,  :default => nil
  config_param :port,     :integer, :default => 3306
  config_param :username, :string,  :default => nil
  config_param :password, :string,  :default => nil

   def initialize
    super
    require 'mysql2'
  end

  def configure(conf)
    super
    begin
      @client = Mysql2::Client.new({
        :host => @host,
        :port => @port,
        :username => @username,
        :password => @password,
        :database => 'mysql'
      })
    rescue
      $log.error "fluent-plugin-rds-slowlog: cannot connect RDS"
    end
  end

  def start
    super
    @watcher = Thread.new(&method(:watch))
  end

  def shutdown
    super
    @watcher.terminate
    @watcher.join
  end

  private
  def watch
    while true
      sleep 10
      output
    end
  end

  def output
    slow_log_data = []
    slow_log_data = @client.query('SELECT * FROM slow_log', :cast => false)

    slow_log_data.each do |row|
      row.each_key {|key| row[key].force_encoding(Encoding::ASCII_8BIT) if row[key].is_a?(String)}
      Fluent::Engine.emit(tag, Fluent::Engine.now, row)
    end

    @client.query('CALL mysql.rds_rotate_slow_log')
  end
end
