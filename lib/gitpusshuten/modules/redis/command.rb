# encoding: utf-8
module GitPusshuTen
  module Commands
    class Redis < GitPusshuTen::Commands::Base
      description "[Module] Redis commands."
      usage       "redis <command> for <enviroment>"
      example     "heavenly redis install                # Installs Redis (system wide) and downloads config template."
      example     "heavenly redis upload-config          # Uploads config template to the server, will install if not"

      def initialize(*objects)
        super

        @command = cli.arguments.shift

        help if command.nil? or e.name.nil?

        @command = @command.underscore
        ##
        # Default Configuration
        @installation_dir           = "/etc/redis"
        @configuration_dir          = @installation_dir
        @configuration_file         = File.join(@configuration_dir, 'redis.conf')
        @local_configuration_dir    = File.join(local.gitpusshuten_dir, 'redis')
        @local_configuration_file   = File.join(@local_configuration_dir, "redis.conf")  
      end
      
      def perform_install!
        if e.installed?('redis-server')
          error "Redis is already installed."
          exit
        end
        message "Going to install Redis Key-Value store systemwide"
        Spinner.return :message => "Installing #{y('Redis')}" do
          e.install!("redis-server")
          g('Done!')
        end
        
        create_file = true
        if File.exist?(@local_configuration_file)
          warning "#{y( @local_configuration_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end  
        if create_file
          download_redis_configuration_from_server!
          message "The redis configuration has been downloaded to#{y( @local_configuration_file)}."
        end
      end
      
      def perform_upload_config!
        unless e.directory?(@installation_dir)
          error "Could not find the Redis installation directory in #{y(@installation_dir)}"
          perform_install!
          exit
        end
    
        unless File.exist?(@local_configuration_file)
          error "Could not find the local Redis configuration file in #{y(@local_configuration_file)}"
          download_redis_configuration_from_server!
          message "Redis configuration has been fetched from the server, edit it and upload it again."
          exit
        end
        Spinner.return :message => "Uploading Redis configuration file #{y(@local_configuration_file)}.." do
          e.scp_as_root(:upload, @local_configuration_file, @configuration_dir)
          g('Done!')
        end
      end
      
      def download_redis_configuration_from_server!
        FileUtils.mkdir_p(@local_configuration_dir)
        Spinner.return :message => "Downloading redis configuration from the server" do
          e.scp_as_root(:download, @configuration_file, "#{@local_configuration_file}")
          g("Finished downloading!")
        end
      end
      
    end
  end
end