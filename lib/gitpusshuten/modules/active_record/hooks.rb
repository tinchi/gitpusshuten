##
# If the user uploaded his own database.yml file (using the Active Record CLI) then
# it'll overwrite the repository version (if it exists) before migrating.
post "Configure and Migrate Database (Active Record)" do
  run "if [[ -f '#{configuration.path}/modules/active_record/#{configuration.sanitized_app_name}.#{environment}.database.yml' ]]; then " +
      "cp '#{configuration.path}/modules/active_record/#{configuration.sanitized_app_name}.#{environment}.database.yml' " +
      "'#{configuration.path}/#{configuration.sanitized_app_name}.#{environment}/config/database.yml'; " +
      "echo 'Uploaded \"database.yml\" file found! Will be using it for the #{environment} environment!'; " +
      "else echo 'Could not find any (pre) uploaded database.yml, skipping.'; " +
      "fi"
  
  run "rake db:create"
  run "rake db:migrate"
end