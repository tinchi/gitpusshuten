require 'fileutils'
require 'open-uri'
require 'yaml'

require 'rubygems'
require 'bundler/setup' unless @ignore_bundler
require 'active_support/inflector'
require 'net/ssh'
require 'net/scp'
require 'highline/import'
require 'rainbow'
require 'json'

if Config::CONFIG['host_os'] =~ /mswin|mingw/
  begin
    require 'win32console'
  rescue LoadError
    puts "You must install 'win32console' gem or use ANSICON 1.31 or later (http://adoxa.110mb.com/ansicon/) to use color on Windows"
  end unless ENV['ANSICON']
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gitpusshuten/**/*'))].each do |file|
  if not File.directory?(file) and not file =~ /\/modules\/.+\/hooks\.rb/
    require file
  end
end

module GitPusshuTen
end
