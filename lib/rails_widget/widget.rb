module WidgetHelpers
  
  def widget_base
    @layout_happened = true
    require_widget ''
    render_widget ''
  end
  
  def render_widget(*path)
    widgets, options = widget_instances path
    widgets.collect do |w|
      # we want widgets rendered from the partial to include first
      partial = w.render_init :partials, options
      js = w.render_init :js, options
      if options[:include_js] && js && !js.empty?
        partial + "\n<script type='text/javascript'>\n#{js}\n</script>"
      else
        javascripts *(@layout_happened ? [ :layout => true ] : []) do
          js
        end
        partial
      end
    end
  end
  
  def require_widget(*path)
    widgets, options = widget_instances path
    widgets.each do |w|
      w.copy_assets
      js  = w.helper_targets :javascripts
      css = w.helper_targets :stylesheets
      javascripts *(js  + [ :cache => w.cache, :layout => @layout_happened ]) unless js.empty?
      stylesheets *(css + [ :cache => w.cache, :layout => @layout_happened ]) unless css.empty?
      templates   *(w.assets[:templates].collect do |t|
        [ File.basename(t), t, options.merge(:options => options) ]
      end) unless w.assets[:templates].empty?
    end
  end
  
  def widget_flash_path(*path)
    flash = path.pop
    "/flash/widgets/#{path.join('/')}/#{flash}"
  end
  
  def widget_image(*path)
    options = path.extract_options!
    image = path.pop
    image_tag "widgets/#{path.join('/')}/#{image}", options
  end
  
  def widget_image_path(*path)
    image = path.pop
    "/images/widgets/#{path.join('/')}/#{image}"
  end
  
  def widget_partial(*path)
    options = path.extract_options!
    partial = path.pop
    path << options
    widgets, options = widget_instances path
    options = {
      :locals  => options.merge(:options => options),
      :partial => "#{path.join('/')}/partials/#{partial}"
    }
    render options
  end
  
  def widget_instances(path)
    @widgets ||= Widgets.new binding, controller, logger
    options = path.extract_options!
    @widgets.build path, options
  end
  
  class Widgets
    attr :widgets, true
    
    def initialize(bind, controller, logger)
      @bind       = bind
      @controller = controller
      @logger     = logger
      @widgets    = {}
    end
    
    def build(path, options)
      opts = {}
      #@logger.info 'RELATED_PATHS ' + related_paths(path).inspect
      widgets = related_paths(path).collect do |r|
        @widgets[r] ||= Assets.new r, @bind, @controller, @logger
        opts.merge! @widgets[r].options
        @widgets[r]
      end
      [ widgets, opts.merge(options) ]
    end
    
    private
    
    def related_paths(paths)
      ordered = []
      last = paths.length - 1
      paths.each_index do |x|
        if x != 0 && File.exists?("app/widgets/#{paths[x]}")
          ordered << related_paths(paths[x..last])
        end
        path = paths[0..x].join '/'
        if File.exists?("app/widgets/#{path}")
          ordered << path
        end
      end
      ordered.flatten
    end
    
    class Assets
      attr :assets,  true
      attr :cache,   true
      attr :options, true
      attr :path,    true
      
      ASSET_TYPES = [ :flash, :images, :javascripts, :stylesheets, :templates, :init_js, :init_partials ]
      
      def initialize(path, bind, controller, logger)
        @bind     = bind
        @controller = controller
        @logger   = logger
        @assets   = {}
        @options  = {}
        @rendered = {}
        @targeted = {}
        @path     = path
        @cache    = cache_name
        update_options
        ASSET_TYPES.each do |type|
          update_asset type
        end
      end
      
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
              File.open t, 'w' do |file|
                file.write @controller.render_to_string(:file => f, :locals => @options.merge(:options => @options))
              end
            end
          end
        end
      end
      
      def helper_targets(type)
        return [] if @targeted[type]
        @targeted[type] = true
        
        from, to = to_path type
        case type
        when :javascripts
          @assets[type].collect do |asset|
            [ to.split('javascripts/')[1], File.basename(asset, '.js') ].join '/'
          end
        when :stylesheets
          @assets[type].collect do |asset|
            sass = asset.include? '.sass'
            [ to.split('stylesheets/')[1], File.basename(asset, sass ? '.sass' : '.css') ].join '/'
          end
        else @assets[type]
        end
      end
      
      def render_init(type, options=@options)
        @rendered[type] ||= {}
        return nil if @rendered[type][options[:id]]
        @rendered[type][options[:id]] = true
        
        @assets["init_#{type}".intern].collect do |f|
          @controller.render_to_string :file => f, :locals => options.merge(:options => options)
        end.join("\n")
      end
      
      private
      
      def cache_name
        'cache/' + (@path.empty? ? 'base' : @path.gsub('/', '_'))
      end
      
      def filename_to_partial(file, remove=nil)
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

      def needs_update?(from, to)
        File.exists?(to) ? File.mtime(from) > File.mtime(to) : true
      end
      
      def to_path(type, path=@path)
        slash = path.empty? ? '' : '/'
        base  = "app/widgets#{slash}#{path}"
        case type
        when :base:          base
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
      
      def update_asset(type)
        @assets[type] ||= []
        from = to_path type
        from = from[0] if from.respond_to?(:pop)
        from = File.directory?(from) ? "#{from}/*" : "#{from}.*"
        Dir[from].sort.each do |f|
          next if type == :javascripts && File.basename(f) == 'init.js'
          @assets[type] << (type == :templates ? filename_to_partial(f, 'app/widgets/') : f)
        end
      end
      
      def update_options(path=@path, empty=false)
        options  = to_path :options, path
        @options = (File.exists?(options) ? eval(File.read(options), @bind) : {}).merge(@options)
        path = path.split('/')[0..-2]
        # empty allows us to retrieve base directory's options
        update_options(path.join('/'), path.empty?) unless empty
      end
    end
  end
end