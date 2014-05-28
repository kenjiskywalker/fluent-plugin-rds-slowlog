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
      unless @tag
        raise Fluent::ConfigError.new("tag is required")
      end
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
      unless @marker
        @marker = '0'
      end
      unless @timezone
        @timezone = '+00:00'
      end
      @parser = MySlog.new
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
      @client = AWS::RDS.new({
        :access_key_id      => @aws_access_key_id,
        :secret_access_key  => @aws_secret_access_key,
        :endpoint           => @aws_rds_endpoint,
        :rds_endpoint       => 'rds.%s.amazonaws.com' % [@aws_rds_region],
        :use_ssl            => true,
      }).client
    end
  end

  def watch
    while true
      sleep 10
      output
    end
  end

  def output
    responce = @download_db_log_file_portion({
      :db_instance_identifier => @db_instance_identifier,
      :log_file_name          => @log_file_name,
      :marker                 => @marker,
    })
    slow_log_data = @parser.parse(responce[:log_file_data ])
    slow_log_data.each do |row|
      row.each_key {|key| row[key].force_encoding(Encoding::ASCII_8BIT) if row[key].is_a?(String)}
      Fluent::Engine.emit(tag, Fluent::Engine.now, row)
    end
    @marker = responce[:marker]
  end
end
