desc 'Updates app/widgets assets'
task :widgets => [ 'widgets:javascripts', 'widgets:stylesheets' ]

namespace :widgets do    
  desc 'Updates app/widgets/javascripts'
  task :javascripts do
    rails_widget_resource 'widgets/javascripts', 'app/widgets/javascripts'
  end
  
  desc 'Updates app/widgets/stylesheets'
  task :stylesheets do
    rails_widget_resource 'widgets/stylesheets', 'app/widgets/stylesheets'
  end
  
  def rails_widget_resource(type, to, reverse=false)
    from = "#{File.dirname(__FILE__)}/../resources/#{type}"
    from, to = to, from if reverse
    puts "=> Removing old #{type}..."
    FileUtils.remove_dir to, true
    FileUtils.mkdir_p to
    puts "=> Copying #{type}..."
    Dir["#{from}/*"].each do |f|
      if File.directory? f
        FileUtils.mkdir_p "#{to}/#{File.basename(f)}"
        FileUtils.cp_r f, to
      else
        FileUtils.cp f, to
      end
    end
end