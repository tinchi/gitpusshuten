module GitPusshuTen
  module Commands
    class Delete < GitPusshuTen::Commands::Base
      description "Deletes the application of the specified environment."
      usage       "delete <environment> environment"
      example     "delete staging environment"
      example     "delete production environment"

      ##
      # Initializes the Delete command
      def initialize(*objects)
        super
        
        help if e.name.nil?
      end

      ##
      # Performs the Delete command
      def perform!
        GitPusshuTen::Log.message "Are you sure you wish to delete #{y(c.application)} from the #{y(e.name)} environment (#{y(c.ip)})?"
        if yes?
          Spinner.return :message => "Deleting #{y(c.application)}.", :put => true do
            environment.delete!
            g("#{y(c.application)} deleted from #{y(e.name)} environment.")
          end
        end
      end

    end
  end
end