class Fluent::RdsSlowlogWithSdkInput < Fluent::Input
  Fluent::Plugin.register_input("rds_slowlog_with_sdk", self)

  # To support log_level option implemented by Fluentd v0.10.43
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  config_param :tag,                    :string,  :default => nil
  config_param :aws_access_key_id,      :string,  :default => nil
  config_param :aws_secret_access_key,  :string,  :default => nil
  config_param :aws_rds_region,         :string,  :default => nil
  config_param :db_instance_identifier, :string,  :default => nil
  config_param :log_file_name,          :string,  :default => 'slowquery/mysql-slowquery.log'
  config_param :timezone,               :string,  :default => 'UTC'
  config_param :offset,                 :string,  :default => '+00:00'
  config_param :duration_sec,           :integer, :default => 10
  config_param :pos_file,               :string,  :default => nil
  config_param :sns_topic_arn,          :string,  :default => nil

  def initialize
    super
    require 'aws-sdk'
    require 'myslog'
    require 'time'
    require 'json'
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
        raise Fluent::ConfigError.new("log_file_name is required")
      end
      unless @timezone
        raise Fluent::ConfigError.new("timezone is required")
      else
        ENV['TZ'] = @timezone
      end
      unless @offset
        raise Fluent::ConfigError.new("offset is required")
      end
      unless @duration_sec
        raise Fluent::ConfigError.new("duration_sec is required")
      end
      unless @pos_file
        @pos_file = '/tmp/fluent-plugin-rds-slowlog-with-sdk-%s.pos' % [@tag]
      end
      unless @sns_topic_arn
        raise Fluent::ConfigError.new("sns_topic_arn is required")
      end
      @parser = MySlog.new
      init_aws_rds_client
      init_aws_sns_client
    rescue
      log.error "fluent-plugin-rds-slowlog-with-sdk: cannot connect RDS"
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
    unless @rds_client
      @rds_client = AWS::RDS.new({
        :access_key_id      => @aws_access_key_id,
        :secret_access_key  => @aws_secret_access_key,
        :rds_endpoint       => 'rds.%s.amazonaws.com' % [@aws_rds_region],
        :use_ssl            => true,
      }).client
    end
  end

  def init_aws_sns_client
    unless @sns_client
      @sns_client = AWS::SNS.new({
        :access_key_id      => @aws_access_key_id,
	:secret_access_key  => @aws_secret_access_key,
	:sns_endpoint       => 'sns.%s.amazonaws.com' % [@aws_rds_region],
	:use_ssl            => true,
      }).client
    end
  end

  def init_marker
    unless File.exist?(@pos_file)
      File.open(@pos_file, 'w'){|fp|fp.sync = true; fp.write '0'}
    end
    unless @marker
      @marker = File.open(@pos_file, 'r').read
    end
  end

  def watch
    while true
      sleep @duration_sec
      output
    end
  end

  def output
    init_marker
    $params = {
      :db_instance_identifier => @db_instance_identifier,
      :log_file_name          => @log_file_name,
      :marker                 => @marker,
    }
    responce = @rds_client.download_db_log_file_portion($params)
    unless responce[:log_file_data].nil?
      slow_log_data = @parser.parse(responce[:log_file_data])
      slow_log_data.each do |row|
        if row.length > 1
          if timestamp = row[:sql].match(/SET timestamp=(\d+)/)
            timestamp = timestamp[1].to_i
            row[:date] = Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S %:z')
          end
	  row[:timezone] = @timezone
	  row[:offset] = @offset
          row.each_key {|key| row[key].force_encoding(Encoding::ASCII_8BIT) if row[key].is_a?(String)}
          Fluent::Engine.emit(tag, timestamp, row)
        end
      end
      File.open(@pos_file, 'w'){|fp|fp.sync = true; fp.write responce[:marker]}
    end
    @marker = responce[:marker]
  rescue AWS::RDS::Errors::InvalidParameterValue => e
    unless @marker == '0'
      File.open(@pos_file, 'w'){|fp|fp.sync = true; fp.write @marker}
      @sns_client.publish({
        :topic_arn => @sns_topic_arn,
        :subject => 'SNS Message',
        :message => {
          :Time    => Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S %:z'),
          :Method  => 'AWS::RDS::Client.download_db_log_file_portion',
	  :Params  => @params,
          :Message => e.message,
        }.to_json,
      })
      @marker = '0'
    end
  end
end
