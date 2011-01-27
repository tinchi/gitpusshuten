module GitPusshuTen
  module Helpers
    module Environment
      module SSH

        ##
        # Tests if the specified directory exists and is a directory
        def directory?(path)
          return true if execute_as_root("if [[ -d '#{path}' ]]; then exit; else echo 1; fi").nil?
          false
        end

        ##
        # Tests if the specified file exists and is a file
        def file?(path)
          return true if execute_as_root("if [[ -f '#{path}' ]]; then exit; else echo 1; fi").nil?
          false
        end
        ##
        # Tests if the specified file or folder exists, doesn't care about type
        def exist?(path)
          return true if execute_as_root("if [[ -e '#{path}' ]]; then exit; else echo 1; fi").nil?
          false
        end

        ##
        #asks if it can write over a remote file on the server
        def ask_to_overwrite_remote(path_to_file)
          create_file = true
          if exist?(path_to_file)
            GitPusshuTen::Log.warning "#{GitPusshuTen.y(path_to_file)} already exists, do you want to overwrite it?"
            create_file = GitPusshuTen.yes?
          end
          create_file

        end
        ##
        #asks if it can write over a local file
        def ask_to_overwrite_local(path_to_file)
          create_file = true
          if File.exist?(path_to_file)
            Log.warning "#{GitPusshuTen.y(path_to_file)} already exists, do you want to overwrite it?"
            create_file = GitPusshuTen.yes?
          end
          create_file
        end

        ##
        # Performs a single command on the remote environment as a user
        def execute_as_user(command)
          @user_password ||= c.password

          while true
            begin
              Net::SSH.start(c.ip, c.user, {
                :password   => @user_password,
                :passphrase => c.passphrase,
                :port       => c.port
                }) do |ssh|
                  response = ssh.exec!(command)
                  GitPusshuTen::Log.silent response 
                  return response
                end
              rescue Net::SSH::AuthenticationFailed
                if @user_attempted
                  GitPusshuTen::Log.error "Password incorrect. Please retry."
                else
                  GitPusshuTen::Log.message "Please provide the password for #{c.user.to_s.color(:yellow)} (#{c.ip.color(:yellow)})."
                  @user_attempted = true
                end
                @user_password = ask('') { |q| q.echo = false }
              end
            end
          end

          ##
          # Performs a command as root
          def execute_as_root(command)
            while true
              begin
                Net::SSH.start(c.ip, 'root', {
                  :password   => @root_password,
                  :passphrase => c.passphrase,
                  :port       => c.port
                  }) do |ssh|
                    response = ssh.exec!(command)
                    GitPusshuTen::Log.silent response 
                    return response
                  end              
                rescue Net::SSH::AuthenticationFailed
                  if @root_attempted
                    GitPusshuTen::Log.error "Password incorrect. Please retry."
                  else
                    GitPusshuTen::Log.message "Please provide the password for #{'root'.color(:yellow)} (#{c.ip.color(:yellow)})."
                    @root_attempted = true
                  end
                  @root_password = ask('') { |q| q.echo = false }
                end
              end
            end

          end
        end
      end
    end