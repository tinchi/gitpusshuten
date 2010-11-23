# encoding: utf-8
module GitPusshuTen
  module Commands
    class ActiveRecord < GitPusshuTen::Commands::Base
      description "[Module] Redis commands."
      usage       "redis <command> for <enviroment>"
      example     "heavenly redis install                 # Installs Redis (system wide) and downloads config template."
      example     "heavenly redis upload-configuration    # Uploads the Redis configuration template to the server, will install Redis if not already present."
      example     "               upload-config           # Alias."

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
        @local_configuration_dir  = File.join(local.gitpusshuten_dir, 'active_record')
        @local_configuration_file = File.join(@local_configuration_dir, "#{e.name}.database.yml")
        
        ##
        # Ensure the directory is always available
        FileUtils.mkdir_p(@local_configuration_dir)
      end

      ##
      # Creates a template for the user to work with
      def perform_create_configuration!
        if File.exist?(@local_configuration_file)
          warning "Configuration file already exists in #{@local_configuration_file}."
          warning "Would you like to overwrite?"
          exit unless yes?
        end
        
        render_database_yml
      end

      def perform_create_config!
        perform_create_configuration!
      end

      def perform_upload_configuration!
        
      end

      def perform_upload_config!
        perform_upload_configuration!
      end

      def perform_download_configuration!
        
      end

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
        end
      end

      def render_database_yml
        config_content = case choose_adapter
        when 'mysql', 'mysql2'
<<-CONFIG
production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  database: #{c.application}.#{e.name}
  pool: 5
  username: #{c.user}
  password:
  host: localhost
  socket: /tmp/mysql.sock
CONFIG
        when 'postgresql'
<<-CONFIG
production:
  adapter: postgresql
  encoding: unicode
  database: #{c.application}.#{e.name}
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
  database: #{c.application}.#{e.name}
  username: #{c.user}
  password: 
CONFIG
        when 'frontbase'
<<-CONFIG
production:
  adapter: frontbase
  host: localhost
  database: #{c.application}.#{e.name}
  username: #{c.user}
  password: 
CONFIG
        when 'ibm_db'
<<-CONFIG
production:
  adapter: ibm_db
  username: #{c.user}
  password:
  database: #{c.application}.#{e.name}
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

    end
  end
end