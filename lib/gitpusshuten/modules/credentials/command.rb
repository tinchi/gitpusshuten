# encoding: utf-8
module GitPusshuTen
  module Commands
    class Credentials < GitPusshuTen::Commands::Base

      description "[Module] Credential commands."
      usage       "credential <command> for <environment>"
      example     "heavenly credential install to staging                 # Installs Credentials (user folder) and symlinks to application initializer (if rails)"
      example     "heavenly credential download from staging              # Downloads Credentials (user folder) from server and installs into current application."

      def initialize(*objects)
        super
        @command = cli.arguments.shift
        help if command.nil? or e.name.nil?

        ##
        # Default Configuration
        @credential_dir                       = File.join(e.home_dir, 'credentials')
        @credential_file_yml                  = File.join(e.home_dir, 'credentials', 'credentials.yml')
        @credential_file_initializer          = File.join(e.app_dir, 'config','initializers', 'credentials.rb')
        @local_credential_dir                 = File.join(local.gitpusshuten_dir, 'credentials')
        @local_credential_file_yml            = File.join(@local_credential_dir, "credentials.yml")
        @local_credential_file_initializer    = File.join(Dir.pwd, "config", "initializers", "credentials.rb")  
      end
      
      def perform_initialize!
        message "Will generate credential files now in #{y(@local_credential_file_yml)} and #{y(@local_credential_file_initializer)}"
        FileUtils.mkdir_p(@local_credential_dir)
        create_initializer
        create_credential_yml
        message "In order to use your credentials in e.g. database.yml use 
        <%=CREDENTIALS[:database_username]=%> 
        <%=CREDENTIALS[:database_password]=%>
        "
        message "Adding credential.rb to your git repo"
        `git add config/initializers/credentials.rb` #Todo, you might have multiple credential files
      end
            
      def perform_download!
        unless e.file?(@credential_file_yml) && e.file?(@credential_file_initializer)
          error "There are no credentials in #{e.app_dir} and #{e.home_dir}"
          exit
        else 
          download_initializer
          download_credential_yml
        end
      end
      
      def perform_upload!
        unless e.directory?(@credential_dir)
          message "Will create a credential folder in #{y(e.home_dir)}"
          e.execute_as_user "mkdir credentials"
        end
        
        unless File.exist?(@local_configuration_file)
          ###Need to fix this and below!!!
          error "Could not find the local credential.yml file in #{y(@local_configuration_file)}"
          download_redis_configuration_from_server!
          message "Redis configuration has been fetched from the server, edit it and upload it again."
          exit
        end
        Spinner.return :message => "Uploading Redis configuration file #{y(@local_configuration_file)}.." do
          e.scp_as_root(:upload, @local_configuration_file, @configuration_dir)
          g('Done!')
        end
      end
      
      def upload_credential_yml
        if ask_to_overwrite_remote(@credential_file_yml)
          Spinner.return :message => "Uploading credentials yml to the server" do
            e.scp_as_user(:upload, @local_credential_file_yml, @credential_file_yml)
            g("credentials.yml finished uploading")
          end
          Spinner.return :message => "Symlinking credential to #{File.join(e.app_dir, 'config', 'credentials')}" do
            e.execute_as_user("ln -sv #{@credential_dir} #{File.join(e.app_dir, 'config')}")
            g("credentials.yml finished uploading")
          end          
        end
      end

      def download_credential_yml!
        if ask_to_overwrite_local(@local_credential_file_yml)
          Spinner.return :message => "Downloading credentials yml from the server.." do
          e.scp_as_user(:download, @credential_file_yml, @local_credential_file_yml)
          g("Finished downloading!")
        end
          message "credentials.yml has been downloaded to#{y(@local_credential_file_yml)}."
        end
      end
      
      def download_initializer!
        if ask_to_overwrite_local(@local_credential_file_initializer)
          Spinner.return :message => "Downloading credentials initializer from the server.." do
          e.scp_as_user(:download, @credential_file_initializer, @local_credential_file_initializer)
          g("Finished downloading!")
        end
          message "credentials.rb has been downloaded to#{y(@local_credential_file_initializer)}."
        end
      end
         
      def create_credential_yml
        message "Going to create the template credentials.yml in #{@local_credential_dir}"
        if ask_to_overwrite_local(@local_credential_file_yml)
          Spinner.return :message => "Creating #{y('credentials.yml')}.." do
            local_credential_yml = File.new(@local_credential_file_yml, "w")
            local_credential_yml.write(yaml_template)
            local_credential_yml.close
            g("Finished creating the YAML Credential template!")
          end
        end
        
      end
      def create_initializer
        message "Going to create the initializer credentials.rb in #{File.join(Dir.pwd, 'config', 'initializers')}"
        if ask_to_overwrite_local(@local_credential_file_initializer)
          Spinner.return :message => "Creating #{y('credentials.rb')}.." do
            local_credential_rb = File.new(@local_credential_file_initializer, "w")
            local_credential_rb.write(initializer_code)
            local_credential_rb.close
            g("Finished creating the initializer!")
          end
        end
      end
      
      def yaml_template
%{database_username: myAwesomeUserName
database_password: myTinySecretPassword"
        }
      end
      
      def initializer_code
%{if Rails.env == 'production'
  raw_config = File.read('#{Dir.pwd}/config/credential/credentials.yml')
else
  raw_config = File.read('#{Dir.pwd}/.gitpusshuten/credential/credentials.yml')
end
CREDENTIALS = YAML.load(raw_config)[Rails.env].symbolize_keys
        }
      end
      
      
      def ask_to_overwrite_remote(path_to_file)
        create_file = true
        if e.file?(path_to_file)
          warning "#{y(path_to_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
        create_file
      end
      
      def ask_to_overwrite_local(path_to_file)
        create_file = true
        if File.exist?(path_to_file)
          warning "#{y(path_to_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
        create_file
      end
            
    end
  end
end