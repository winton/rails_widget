require 'rails_generator'
require 'rails_generator/commands'

module RailsWidget
  module Generator
    
    # Copies <tt>templates/#{from}/**/*<tt> to <tt>app/widgets/#{to}/**/*</tt> after prompting.
    #
    def asset(name, from, to)
      javascripts = Dir[source_path("#{from}/**/*")]
      javascripts.collect!  { |js| js.split("templates/#{from}/")[1] }
      javascripts.delete_if { |js| File.exists?("app/widgets/#{to}/#{js}") }
      unless javascripts.empty?
        puts "\n"
        puts "This plugin requires #{name}. Create the following files? (y/n)"
        javascripts.each { |js| puts "  app/widgets/#{to}/#{js}" }
        answer = gets.strip.downcase[0..0] == 'y'
        if answer
          directory "app/widgets/#{to}"
          javascripts.each do |js|
            if File.directory?(source_path("#{from}/#{js}"))
              directory "app/widgets/#{to}/#{js}"
            else
              file "#{from}/#{js}", "app/widgets/#{to}/#{js}"
            end
          end
        end
        puts"\n"
      end
    end
    
  end
end