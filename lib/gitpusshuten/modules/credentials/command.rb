# encoding: utf-8
module GitPusshuTen
  module Commands
    class Credentials < GitPusshuTen::Commands::Base

      description "[Module] Credential commands."
      usage       "credentials <command> for <environment>"
      example     "heavenly credentials initialize for production          # Will initialize the credential folder in gitpusshuten root and create an initializer in config/initializers"
      example     "heavenly credentials upload to staging                 # Uploads the credentials folder to the server and symlinks to application"
      example     "heavenly credentials download from staging              # Downloads the credentials folder from server to gitpusshuten root"

      def initialize(*objects)
        super
        @command = cli.arguments.shift
        help if command.nil? or e.name.nil?

        ##
        # Default Configuration
        @credentials_dir                       = File.join(e.home_dir, 'credentials')
        @credentials_file_yml                  = File.join(e.home_dir, 'credentials', 'credentials.yml')
        @credentials_file_initializer          = File.join(e.app_dir, 'config','initializers', 'credentials.rb')
        @local_credentials_dir                 = File.join(local.gitpusshuten_dir, 'credentials')
        @local_credentials_file_yml            = File.join(@local_credentials_dir, "credentials.yml")
        @local_credentials_file_initializer    = File.join(Dir.pwd, "config", "initializers", "credentials.rb")  
      end
      
      def perform_initialize!
        message "Will generate credentials files now in #{y(@local_credentials_file_yml)} and #{y(@local_credentials_file_initializer)}"
        create_initializer
        create_credentials
        message "In order to use your credentials in e.g. database.yml use 
        <%=CREDENTIALS[:database_username]=%> 
        <%=CREDENTIALS[:database_password]=%>
        "
        message "Adding credentials.rb to your git repo"
        `git add config/initializers/credentials.rb` #Todo, you might have multiple credentials files
      end
            
      def perform_download!
          download_credentials
          download_initializer unless File.exist?(@local_credentials_file_initializer)
      end
      
      def perform_upload!
        unless e.exist?(e.app_dir)
          error "You haven't pushed your application yet"
          exit
        else
          upload_credentials
        end
      end
      def upload_credentials
        unless e.file?(@credentials_file_initializer) && File.exist?(@local_credentials_file_yml)
          error "You don't have any credentials in this project"
          message "You can either initialize credentials or download existing from the server"
          exit
        end
        if ask_to_overwrite_remote(@credentials_dir)
          Spinner.return :message => "Uploading credentials to the server" do
            e.scp_as_user(:upload, @local_credentials_dir, @credentials_dir, {:recursive => true})
            g("credentials folder finished uploading")
          end
          
          Spinner.return :message => "Symlinking credentials to #{File.join(e.app_dir, 'config', 'credentials')}" do
            e.execute_as_user("ln -sv #{@credentials_dir} #{File.join(e.app_dir, 'config')}")
            g("credentials symlinked to the project: #{@credentials_file_yml}")
          end          
          
        end
      end

      def download_credentials        
        unless e.exist?(@credentials_dir)
          error "There are no credentials in #{e.home_dir}"
          exit        
        end
        if ask_to_overwrite_local(@local_credentials_dir)
          Spinner.return :message => "Downloading credentials from the server.." do
            e.scp_as_user(:download, @credentials_dir, local.gitpusshuten_dir, {:recursive => true})
            g("Finished downloading!")
          end
          message "credentials have been downloaded to #{y(@local_credentials_dir)}."
        else
          warning "Did not download credentials"
        end
      end
      
      def download_initializer
        unless e.file?(@credentials_file_initializer)
          error "There is no initializer in #{File.join(e.app_dir, "config", "initializers")}"
          create_initializer
          exit
        end
        if ask_to_overwrite_local(@local_credentials_file_initializer)
          Spinner.return :message => "Downloading credentials initializer from the server.." do
          e.scp_as_user(:download, @credentials_file_initializer, @local_credentials_file_initializer)
          g("Finished downloading!")
        end
          message "credentials.rb has been downloaded to#{y(@local_credentials_file_initializer)}."
        end
      end
         

#Check if files exists, ask for overwrite and create
      def create_credentials
        FileUtils.mkdir_p(@local_credentials_dir)
        message "Going to create the credentials.yml in #{@local_credentials_dir}"
        if ask_to_overwrite_local(@local_credentials_file_yml)
          Spinner.return :message => "Creating #{y('credentials.yml')}.." do
            local_credentials_yml = File.new(@local_credentials_file_yml, "w")
            local_credentials_yml.write(yaml_template)
            local_credentials_yml.close
            g("Finished creating the credentials.yml")
          end
        end  
      end
      
      def create_initializer
        message "Going to create the initializer credentials.rb in #{File.join(Dir.pwd, 'config', 'initializers')}"
        if ask_to_overwrite_local(@local_credentials_file_initializer)
          Spinner.return :message => "Creating #{y('credentials.rb')}.." do
            local_credentials_rb = File.new(@local_credentials_file_initializer, "w")
            local_credentials_rb.write(initializer_code)
            local_credentials_rb.close
            g("Finished creating the initializer!")
          end
        end
      end
      
      
#Extract into boilerplate module

      def yaml_template
%{database_username: myAwesomeUserName
database_password: myTinySecretPassword}
      end
      
      def initializer_code
%{if Rails.env == 'production'
  raw_config = File.read('#{Dir.pwd}/config/credentials/credentials.yml')
else
  raw_config = File.read('#{Dir.pwd}/.gitpusshuten/credentials/credentials.yml')
end
CREDENTIALS = YAML.load(raw_config)[Rails.env].symbolize_keys}
      end
      

#Extract these into helper methods, the e.exist? method is new and needs to replace a some snippets in the code base
      def ask_to_overwrite_remote(path_to_file)
        create_file = true
        if e.exist?(path_to_file)
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