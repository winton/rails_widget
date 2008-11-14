# ==== Example
#   script/generate widget widget_name
#
class WidgetGenerator < Rails::Generator::Base 
  def manifest
    name   = args.shift.underscore
    widget = "app/widgets/#{name}"
    only   = args.collect { |a| a.intern }
    types  = [ :flash, :generator, :images, :javascripts, :partials, :stylesheets, :templates ]
    
    record do |m|
      # Create widget base directory
      m.directory widget
      
      # Create directories for...
      if only.empty?
        # All assets
        only = types
      else
        # Some assets
        only.reject! { |type| !types.include?(type) }
      end
      only.each { |type| m.directory "#{widget}/#{type}" }
      
      # Create init files
      [ :javascripts, :partials, :stylesheets ].each do |type|
        if only.include?(type)
          init = case type
          when :javascripts
            'init.js'
          when :partials
            '_init.erb'
          when :stylesheets
            'init.css'
          end
          m.file 'blank', "#{widget}/#{type}/#{init}"
        end
      end
      
      # Create install.rb, options.rb
      m.file 'blank', "#{widget}/install.rb"
      m.template 'options.rb', "#{widget}/options.rb", :assigns => { :name => name }
      
      # Create generator
      if only.include?(:generator)
        generator = "#{widget}/generator"
        m.directory "#{generator}/templates"
        m.template 'generator.rb', "#{generator}/#{name}_generator.rb", :assigns => { :name => name }
        # Add symlink
        links = "#{RAILS_ROOT}/lib/generators"
        FileUtils.mkdir_p links
        FileUtils.ln_sf "#{RAILS_ROOT}/#{widget}/generator", "#{links}/#{name}"
      end
    end 
  end 
end