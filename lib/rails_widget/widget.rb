module RailsWidget
  
  # Stores information about a widget and renders assets to <tt>public/</tt> when necessary.
  #
  class Widget
    attr :assets,  true # Paths for each ASSET_TYPE
    attr :cache,   true # Cache path for Rails asset helpers
    attr :options, true # Options hash from options.rb
    attr :path,    true # Path to widget

    ASSET_TYPES = [ :flash, :images, :javascripts, :stylesheets, :templates, :init_css, :init_js, :init_partials ]

    # Calls <tt>update_options</tt> and <tt>update_asset</tt> for each <tt>ASSET_TYPE</tt>.
    #
    def initialize(path, bind, controller, logger)
      @path = path
      @bind = bind
      @controller = controller
      @logger = logger

      @assets = {}
      @options  = {}
      @targeted = {}

      update_options
      ASSET_TYPES.each do |type|
        update_asset type
      end
    end
    
    # Returns a cache path suitable for Rails asset helpers.
    #
    def cache
      'cache/' + (@path.empty? ? 'base' : @path.gsub('/', '_'))
    end

    # Copies widget images to <tt>public/images/widgets</tt>.
    #
    # Copies widget flash files to <tt>public/flash/widgets</tt>.
    #
    # Renders javascripts to <tt>public/javascripts/widgets</tt>.
    #
    # Renders stylesheets to <tt>public/stylesheets/widgets</tt>.
    #
    def copy_assets
      @assets.each do |key, value|
        from, to = to_path key
        value.each do |asset|
          base = File.basename asset
          f = [ from, base ].join '/'
          t = [ to,   base ].join '/'
          t.gsub!('/stylesheets/', '/stylesheets/sass/') if t.include?('.sass')
          next unless needs_update?(f, t)
          case key
          when :flash, :images
            FileUtils.mkdir_p to
            FileUtils.cp_r f, t
          when :javascripts, :stylesheets
            FileUtils.mkdir_p File.dirname(t)
            #FileUtils.cp_r f, t
            File.open t, 'w' do |file|
              file.write @controller.render_to_string(:file => f, :locals => @options.merge(:options => @options))
            end
          end
        end
      end
    end
    
    # Returns asset paths to be included via the Assets helpers for a particular <tt>ASSET_TYPE</tt>.
    #
    # See <tt>add_static_assets (Widgets)</tt>.
    #
    def asset_paths(type, options)
      return [] if @targeted[type]
      @targeted[type] = true
      
      assets = reject_ignored @assets[type], options
      from, to = to_path type
      
      case type
      when :javascripts
        assets.collect do |asset|
          [ to.split('javascripts/')[1], File.basename(asset, '.js') ].join '/'
        end
      when :stylesheets
        assets.collect do |asset|
          sass = asset.include? '.sass'
          [ to.split('stylesheets/')[1], File.basename(asset, sass ? '.sass' : '.css') ].join '/'
        end
      else assets
      end
    end
    
    # Renders and returns the init file for a particular <tt>ASSET_TYPE</tt>.
    #
    # The render will not occur if it has already happened with the same <tt>:id</tt> option.
    #
    def render_init(type, options=@options)
      assets = reject_ignored @assets["init_#{type}".intern], options
      assets.collect do |f|
        @controller.render_to_string :file => f, :locals => options.merge(:options => options)
      end.join("\n")
    end

    private

    # Converts a full file name to a path that can be used by <tt>render :partial</tt>.
    #
    # Optionally removes string(s) from the returned path.
    #
    def filename_to_partial(file, remove=nil) #:doc:
      base = File.basename file
      dir  = File.dirname file
      file = [ dir, (base[0..0] == '_' ? base[1..-1] : base ).split('.')[0..-2].join('.') ].join '/'
      if remove
        if remove.respond_to?(:pop)
          remove.each { |r| file.gsub! r, '' }
        else
          file.gsub! remove, ''
        end
      end
      file
    end
    
    # Returns true if <tt>from</tt> is newer than <tt>to</tt> or <tt>to</tt> does not exist.
    #
    def needs_update?(from, to) #:doc:
      File.exists?(to) ? File.mtime(from) > File.mtime(to) : true
    end
    
    # Returns an array of assets with options[:ignore] paths removed.
    #
    def reject_ignored(assets, options)
      if ignore = options[:ignore]
        ignore = ignore.respond_to?(:pop) ? ignore : [ ignore ]
        ignore.collect! do |i|
          i = "app/widgets/#{i}"
          assets.select do |a|
            a[0..i.length-1] == i
          end
        end
        ignore.flatten.compact.each do |i|
          assets.delete i
        end
      end
      assets
    end
    
    # Returns a full path for the specified <tt>ASSET_TYPE</tt>.
    #
    def to_path(type, path=@path) #:doc:
      slash = path.empty? ? '' : '/'
      base  = "app/widgets#{slash}#{path}"
      case type
      when :base:          base
      when :init_css:      base + '/stylesheets/init'
      when :init_js:       base + '/javascripts/init'
      when :init_partials: base + '/partials/_init'
      when :options:       base + '/options.rb'
      when :templates:     base + '/templates'
      when :flash:       [ base + '/flash',       "public/flash/widgets"       + slash + path ]
      when :images:      [ base + '/images',      "public/images/widgets"      + slash + path ]
      when :javascripts: [ base + '/javascripts', "public/javascripts/widgets" + slash + path ]
      when :stylesheets: [ base + '/stylesheets', "public/stylesheets/widgets" + slash + path ]
      end
    end
    
    # Updates <tt>@assets[type]</tt> with an array of paths for the specified <tt>ASSET_TYPE</tt>.
    #
    def update_asset(type) #:doc:
      @assets[type] ||= []
      from = to_path type
      from = from[0] if from.respond_to?(:pop)
      from = File.directory?(from) ? "#{from}/*" : "#{from}.*"
      Dir[from].sort.each do |f|
        next if (type == :javascripts || type == :stylesheets) && File.basename(f)[0..3] == 'init'
        @assets[type] << (type == :templates ? filename_to_partial(f, 'app/widgets/') : f)
      end
    end

    # Assigns the hash in <tt>options.rb</tt> (if it exists) to <tt>@options</tt>.
    #
    def update_options(path=@path, empty=false) #:doc:
      path = to_path :options, path
      @options = File.exists?(path) ? eval(File.read(path), @bind) : {}
    end
  end
end