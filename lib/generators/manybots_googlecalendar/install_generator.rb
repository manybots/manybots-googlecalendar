require 'rails/generators'
require 'rails/generators/base'
require 'rails/generators/migration'


module ManybotsGooglecalendar
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path("../../templates", __FILE__)
      
      class_option :routes, :desc => "Generate routes", :type => :boolean, :default => true
      class_option :migrations, :desc => "Generate migrations", :type => :boolean, :default => true
      
      def self.next_migration_number(path)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
      
      desc 'Mounts Google Calendar Observer at "/manybots-googlecalendar"'
      def add_manybots_github_routes
        route 'mount ManybotsGooglecalendar::Engine => "/manybots-googlecalendar"' if options.routes?
      end
      
      desc "Copies ManybotsGooglecalendar migrations"
      def create_model_file
        migration_template "create_manybots_googlecalendar_events.rb", "db/migrate/create_manybots_googlecalendar_events.manybots_googlecalendar.rb"
      end
      
      desc "Creates a ManybotsGooglecalendar initializer"
      def copy_initializer
        template "manybots-googlecalendar.rb", "config/initializers/manybots-googlecalendar.rb"
      end
      
      def show_readme
        readme "README" if behavior == :invoke
      end
      
    end
  end
end
