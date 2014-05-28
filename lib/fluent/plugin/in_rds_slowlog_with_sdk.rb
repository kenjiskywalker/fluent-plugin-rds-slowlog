class Fluent::RdsSlowlogWithSdkInput < Fluent::Input
  Fluent::Plugin.register_input("rds_slowlog_with_sdk", self)

  # To support log_level option implemented by Fluentd v0.10.43
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  config_param :tag,      :string
  config_param :host,     :string,  :default => nil
  config_param :port,     :integer, :default => 3306
  config_param :username, :string,  :default => nil
  config_param :password, :string,  :default => nil

  def initialize
    super
    require 'aws-sdk'
    require 'myslog'
  end

  def configure(conf)
    super
    begin
      unless @aws_access_key_id
        raise Fluent::ConfigError.new("aws_access_key_id is required")
      end
      unless @aws_secret_access_key
        raise Fluent::ConfigError.new("aws_secret_access_key is required")
      end
      unless @aws_rds_region
        raise Fluent::ConfigError.new("aws_rds_region is required")
      end
      unless @db_instance_identifier
        raise Fluent::ConfigError.new("db_instance_identifier is required")
      end
      unless @log_file_name
        @log_file_name = 'slowquery/mysql-slowquery.log'
      end
      unless @marker_file_path
        raise Fluent::ConfigError.new("marker_file_path is required")
      end
      init_aws_rds_client
    rescue
      log.error "fluent-plugin-rds-slowlog-whith-sdk: cannot connect RDS"
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
  
  def init_aws_rds_client
    unless @client
      options = {}
      options[:access_key_id]      = @aws_access_key_id
      options[:secret_access_key]  = @aws_secret_access_key
      options[:endpoint]           = @aws_rds_endpoint
      options[:rds_endpoint]       = 'rds.%s.amazonaws.com' % [@aws_rds_region]
      options[:use_ssl]            = true
      rds = AWS::RDS.new(options)
      @client = rds.client
    end
  end

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
