namespace :widget do
  
  # ==== Example
  #   rake widget:install git=git@github.com:user/repository.git
  #
  desc 'Install a widget'
  task :install do
    puts "\n"
    
    # Make the widgets base directory
    path = "#{RAILS_ROOT}/app/widgets"
    FileUtils.mkdir_p path
    
    # Currently installs from git repositories only
    if ENV['git']
      
      # git parameter can be comma delimited
      ENV['git'].split(',').each do |repo|
        base = File.basename repo, '.git'
        path = "#{path}/#{base}"
        
        # Remove widget if already exists
        if File.exists?(path)
          puts "Widget already exists. Remove? (y/n)"
          abort = STDIN.gets.chomp.downcase != 'y'
          unless abort
            puts "Removing #{base}..."
            FileUtils.rm_rf path
          end
        end
        
        if abort
          puts "Install aborted!"
        else
          # Clone git repo
          puts "Cloning #{base}..."
          `git clone #{repo} #{path}`
        
          # Run install.rb
          if File.exists?("#{path}/install.rb")
            puts "Installing #{base}..."
            eval File.read("#{path}/install.rb")
          end
          puts "Installed!"
        end
      end
    else
      # Print the usage
      puts "Usage\n  rake widget:install git=git@github.com:user/repository.git"
    end
    puts "\n"
  end
  
  
  # ==== Example
  #   rake widget:remove git=git@github.com:user/repository.git
  #
  desc 'Remove a widget'
  task :remove do
    puts "\n"
    path = "#{RAILS_ROOT}/app/widgets"
    
    # Currently installs from git repositories only
    if ENV['git']
      
      # git parameter can be comma delimited
      ENV['git'].split(',').each do |repo|
        base = File.basename repo, '.git'
        path = "#{path}/#{base}"
        
        # Remove widget if already exists
        if File.exists?(path)
          puts "Removing #{base}..."
          FileUtils.rm_rf path
          puts "Removed!"
        else
          puts "Not found!"
        end
      end
    else
      puts "Usage\n  rake widget:remove git=git@github.com:user/repository.git"
    end
    puts "\n"
  end

end