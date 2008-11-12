namespace :widget do
  
  # ==== Example
  #   rake widget:production
  #
  desc 'Sets up a production app (run after deploy)'
  task :production do
    `script/runner 'RailsWidget::Widgets.setup_production'`
  end
  
  # ==== Example
  #   rake widget:clean
  #
  desc 'Clean temporary widget files'
  task :clean do
    puts "\n"
    [ 'javascripts/widgets', 'flash/widgets', 'images/widgets', 'stylesheets/widgets', 'stylesheets/sass/widgets' ].each do |f|
      f = "public/#{f}"
      if File.exists?(f)
        puts "Removing #{f}..."
        FileUtils.rm_rf(f)
      end
    end
    puts "Clean!"
    puts "\n"
  end
  
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
          
          # Add symbolic link for generators
          generator = "#{path}/generator"
          if File.exists?(generator)
            links = "#{RAILS_ROOT}/lib/generators"
            FileUtils.mkdir_p links
            FileUtils.ln_sf generator, "#{links}/#{base}"
          end
        
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
        
        if File.exists?(path)
          # Remove symbolic link for generators
          link = "#{RAILS_ROOT}/lib/generators/#{base}"
          FileUtils.rm_rf(link) if File.exists?(link)
          
          # Remove widget
          puts "Removing #{base}..."
          FileUtils.rm_rf path
          puts "Removed!"
        else
          puts "Not found!"
        end
      end
    else
      # Print the usage
      puts "Usage\n  rake widget:remove git=git@github.com:user/repository.git"
    end
    puts "\n"
  end

end