# encoding: utf-8
module GitPusshuTen
  module Commands
    class ActiveRecord < GitPusshuTen::Commands::Base
      description       "[Module] Active Record commands."
      long_description  "By using the Active Record CLI utility you can avoid checking your database.yml into your git repository.\n" +
                        "Use the examples below to create, and then upload your custom database.yml for the desired environment to the server\n" +
                        "and the Active Record module will handle the rest! After the deployment of your application this uploaded database.yml file will\n" +
                        "be placed inside your APP_ROOT/config/database.yml. If the database.yml file already exists there, it'll overwrite it.\n" +
                        "This is a security measure, since it's generally bad practice to store any sensitive information in your Git repository."
                        
      usage             "active_record <command> for <enviroment>"
      example           "heavenly active_record create_configuration    # Creates a template for your remote database."
      example           "                       create_config           # Alias."  
      example           "heavenly active_record upload_configuration    # Uploads your configuration file to the remote server."
      example           "                       upload_config           # Alias."
      example           "heavenly active_record download_configuration  # Downloads your configuration file from the remote server."
      example           "                       download_config         # Alias."

      def initialize(*objects)
        super
        
        ##
        # Set the command
        @command = cli.arguments.shift
        
        ##
        # Display the help screen if either the command
        # or environment name hasn't been set
        help if command.nil? or e.name.nil?
        
        ##
        # Default Configuration
        @local_configuration_dir    = File.join(local.gitpusshuten_dir, 'active_record')
        @local_configuration_file   = File.join(@local_configuration_dir, "#{e.name}.database.yml")
        @remote_configuration_dir   = File.join(c.path, 'modules', 'active_record')
        @remote_configuration_file  = File.join(@remote_configuration_dir, "#{e.sanitized_app_name}.#{e.name}.database.yml")
        
        ##
        # Ensure the directory is always available
        FileUtils.mkdir_p(@local_configuration_dir)
      end

      ##
      # Creates a template for the user to work with
      def perform_create_configuration!
        overwrite_if_exists?
        
        render_database_yml
        message "Created #{y(@local_configuration_file)}."
      end

      ##
      # Alias to perform_create_configuration!
      def perform_create_config!
        perform_create_configuration!
      end

      ##
      # Uploads the local configuration file to the remote server.
      def perform_upload_configuration!
        requires_user_existence!
        prompt_for_user_password!
        
        if not File.exist?(@local_configuration_file)
          error "Could not find #{y(@local_configuration_file)}."
          error "Either download an existing one from your server with:"
          standard "\n\s\s#{y("heavenly active_record download-configuration from #{e.name}")}\n\n"
          error "Or create a new template with:"
          standard "\n\s\s#{y("heavenly active_record create-configuration for #{e.name}")}"
          exit
        end
        
        ##
        # Ensure the remote active_record module directory exits
        # and upload the local file to the remote file location
        Spinner.return :message => "Uploading the database configuration file.." do
          e.execute_as_user("mkdir -p '#{@remote_configuration_dir}'")
          e.scp_as_user(:upload, @local_configuration_file, @remote_configuration_file)
          g('Done!')
        end
      end

      ##
      # Alias to perform_upload_configuration!
      def perform_upload_config!
        perform_upload_configuration!
      end

      ##
      # Downloads the configuration file from the remote server.
      def perform_download_configuration!
        overwrite_if_exists?
        
        ##
        # Don't proceed unless the file exists
        if not e.file?(@remote_configuration_file)
          error "Configuration could not be found on the server in #{y(@remote_configuration_file)}."
          exit
        end
        
        ##
        # Ensure the remote active_record module directory exits
        # and upload the local file to the remote file location
        Spinner.return :message => "Downloading the database configuration file.." do
          e.scp_as_user(:download, @remote_configuration_file, @local_configuration_file)
          g('Done!')
        end        
      end

      ##
      # Alias to perform_download_configuration!
      def perform_download_config!
        perform_download_configuration!
      end

      ##
      # Prompts the user to choose a database adapter
      def choose_adapter
        choose do |menu|
          menu.prompt = ''
          menu.choice('mysql', 'mysql2')
          menu.choice('postgresql')
          menu.choice('sqlite3')
          menu.choice('oracle')
          menu.choice('frontbase')
          menu.choice('ibm_db')
        end
      end

      ##
      # Render the chosen Active Record database template file 
      def render_database_yml
        config_content = case choose_adapter
        when 'mysql', 'mysql2'
<<-CONFIG
production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: #{e.sanitized_app_name}_#{e.name}
  pool: 5
  username: #{c.user}
  password:
  host: localhost
  # socket: /tmp/mysql.sock
CONFIG
        when 'postgresql'
<<-CONFIG
production:
  adapter: postgresql
  encoding: unicode
  database: #{e.sanitized_app_name}_#{e.name}
  pool: 5
  username: #{c.user}
  password:
CONFIG
        when 'sqlite3'
<<-CONFIG
production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
CONFIG
        when 'oracle'
<<-CONFIG
production:
  adapter: oracle
  database: #{e.sanitized_app_name}_#{e.name}
  username: #{c.user}
  password: 
CONFIG
        when 'frontbase'
<<-CONFIG
production:
  adapter: frontbase
  host: localhost
  database: #{e.sanitized_app_name}_#{e.name}
  username: #{c.user}
  password: 
CONFIG
        when 'ibm_db'
<<-CONFIG
production:
  adapter: ibm_db
  username: #{c.user}
  password:
  database: #{e.sanitized_app_name}_#{e.name}
  #schema: db2inst1
  #host: localhost
  #port: 50000
  #account: my_account
  #app_user: my_app_user
  #application: my_application
  #workstation: my_workstation
  #security: SSL
  #timeout: 10
  #authentication: SERVER
  #parameterized: false
CONFIG
        end # end case statement
        
        File.open(@local_configuration_file, 'w') do |file|
          file << config_content
        end
      end

      ##
      # If the local configuration file exists, it will ask the
      # user whether he wants to overwrite it
      def overwrite_if_exists?
        if File.exist?(@local_configuration_file)
          warning "Configuration file already exists in #{@local_configuration_file}."
          warning "Would you like to overwrite?"
          exit unless yes?
        end
      end

    end
  end
end