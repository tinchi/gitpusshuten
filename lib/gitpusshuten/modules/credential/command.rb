# encoding: utf-8
module GitPusshuTen
  module Commands
    class Credential < GitPusshuTen::Commands::Base

      description "[Module] Credential commands."
      usage       "credential <command> for <environment>"
      example     "heavenly credential install to staging                # Installs Redis (system wide) and downloads config template."
      example     "heavenly redis upload to staging   # Uploads the Redis configuration template to the server, will install Redis if not already present."
      example     "               upload to staging          # Alias."

      def initialize(*objects)
        super
        @command = cli.arguments.shift
        help if command.nil? or e.name.nil?
        
        ##
        # Default Configuration
        @credential_dir                       = File.join(e.home_dir, 'credential')
        @credential_file_yml                  = File.join(e.home_dir, 'credential', 'credential.yml')
        @credential_file_initializer          = File.join(e.app_dir, 'initializers', 'credential.rb')
        @local_credential_dir                 = File.join(local.gitpusshuten_dir, 'credential')
        @local_credential_file_yml            = File.join(@local_credential_dir, "credential.yml")
        @local_credential_file_initializer    = File.join(Dir.pwd, "config", "initializers", "credential.rb")  
      end

      def perform_download!
        unless e.file?(@credential_file_yml)
          error "credential.yml file does not exist on the server in #{@installation_dir}"
          exit
        end        
        if e.file?(@credential_file_initializer)
          download_initializer!
        else
          error "Credential initializer does not exist"
          create_initializer!
        end
        message "Going to download the credential.yml file from #{@installation_dir} on the server"
        Spinner.return :message => "Downloading #{y('credential.yml')}.." do
          FileUtils.mkdir_p(@local_credential_dir)
          e.scp_as_user(:download, @credential_file_yml, @local_configuration_file_yml)
          g("Finished downloading!")
        end
        
      end
      
      def perform_upload!
        unless e.directory?(@credential_dir)
          error "Could not find the credential directory in #{y(e.user_dir)}"
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


      def download_initializer!
        if ask_to_overwrite_local(@local_credential_file_initializer)
          Spinner.return :message => "Downloading credential initializer from the server.." do
          e.scp_as_root(:download, @credential_file_initializer, @local_credential_file_initializer)
          g("Finished downloading!")
        end
          message "The credential.rb has been downloaded to#{y(@local_credential_file_initializer)}."
        end
      end
      
      def create_initializer!
        message "Going to create the initializer credential.rb in #{File.join(Dir.pwd, 'config', 'initializers')}"
        if ask_to_overwrite_local(@local_credential_file_initializer)
          Spinner.return :message => "Creating #{y('credential.rb')}.." do
            local_credential_rb = File.new(@local_credential_file_initializer, "w")
            local_credential_rb.write(initializer_code)
            local_credential_rb.close
            g("Finished creating the initializer!")
          end
        end
      end
      
      def initializer_codex
        """ if Rails.env == 'production'
              raw_config = File.read('#{Rails.root}/config/credential/credential.yml')
            else
              raw_config = File.read('#{Rails.root}/.gitpusshuten/credential/credential.yml')
            end
            CREDENTIALS = YAML.load(raw_config)[Rails.env].symbolize_keys
        """
      end
      
      
      def ask_to_overwrite_remote(path_to_file)
        create_file = true
        if e.file?(path_to_file)
          warning "#{y(path_to_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
      end
      def ask_to_overwrite_local(path_to_file)
        create_file = true
        if File.exist?(path_to_file)
          warning "#{y(path_to_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end          
      end
      
    end
  end
end