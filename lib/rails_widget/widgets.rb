module RailsWidget
  
  # See <tt>RailsWidget</tt>.
  #
  def widget(*path)
    @assets  ||= Assets.new  binding, controller, logger
    @widgets ||= Widgets.new @assets, binding, controller, logger
    options = path.extract_options!
    @widgets.build path, options
  end
  
  # Returns a path for a flash asset.
  #
  # ==== Example
  #   <%= flash_path :some, :widget, 'flash.swf' %>
  #   # => 'app/widgets/some/widget/flash/flash.swf'
  #
  def flash_path(*path)
    flash = path.pop
    "/flash/widgets/#{path.join('/')}/#{flash}"
  end
  
  # Returns an image tag for an image asset.
  #
  # ==== Example
  #   <%= image :some, :widget, 'image.png', :border => 0 %>
  #   # => '<img src="app/widgets/some/widget/images/image.png" border=0 />'
  #
  def image(*path)
    options = path.extract_options!
    image = path.pop
    image_tag "widgets/#{path.join('/')}/#{image}", options
  end
  
  # Returns an image path for an image asset.
  #
  # ==== Example
  #   <%= image_path :some, :widget, 'image.png' %>
  #   # => 'app/widgets/some/widget/images/image.png'
  #
  def image_path(*path)
    image = path.pop
    "/images/widgets/#{path.join('/')}/#{image}"
  end
  
  # Renders a partial asset.
  #
  # ==== Example
  #   <%= partial :some, :widget, 'partial', :locals => { :x => true } %>
  #   # => render :partial => 'app/widgets/some/widget/partials/partial', :locals => { :x => true }
  #
  def partial(*path)
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
  
  # Creates and recycles instances of the Widget class.
  #
  class Widgets
    attr :widgets, true
    
    # Should be called from a helper. See <tt>widget (RailsWidget)</tt>.
    #
    # ==== Example
    #   w = Widgets.new Assets.new(binding, controller), binding, controller, logger
    #
    def initialize(assets, bind, controller, logger)
      @assets     = assets
      @bind       = bind
      @controller = controller
      @logger     = logger
      @widgets    = {}
      build # app/widgets acts as a widget
    end
    
    # See <tt>widget (RailsWidget)</tt>.
    #
    def build(path=[''], options={})
      widgets, opts = instanciate path
      options = opts.merge options        # Merge the options parameter (highest precedence)
      add_static_assets  widgets, options
      return_init_assets widgets, options # Returns the init partial to <tt>widget (RailsWidget)</tt>
    end
    
    # Creates Widget instances for the widget path and its <tt>related_paths</tt> if they do not already exist.
    #
    # Returns an array of widget instances and merged <tt>options.rb</tt> hashes.
    #
    # ==== Example
    #   w.build([ :some, :widget ], { :option1 => true })
    #   # => [ #<Widget>, #<Widget>, #<Widget> ], { :option1 => true, :option2 => true }
    #
    # (See the <tt>related_paths</tt> example for context.)
    #
    def instanciate(path)
      opts = {}
      widgets = related_paths(path).collect do |r|
        @widgets[r] ||= Widget.new r, @bind, @controller, @logger
        opts.merge! @widgets[r].options
        @widgets[r]
      end
      [ widgets, opts ]
    end
    
    # Calls <tt>copy_assets (Widget)</tt> for a number of <tt>Widget</tt> instances.
    #
    # Also adds static (non-init) assets to the layout via the Assets helpers.
    #
    def add_static_assets(widgets, options)
      widgets.each do |w|
        w.copy_assets
        js  = w.asset_paths :javascripts
        css = w.asset_paths :stylesheets
        @assets.javascripts *(js  + [ :cache => w.cache ]) unless js.empty?
        @assets.stylesheets *(css + [ :cache => w.cache ]) unless css.empty?
        @assets.templates   *(w.assets[:templates].collect do |t|
          { :id => File.basename(t), :partial => t, :locals => options.merge(:options => options) }
        end) unless w.assets[:templates].empty?
      end
    end
    
    # Renders and returns the init partial (<tt>partials/_init.*</tt>) for a number of <tt>Widget</tt> instances.
    #
    # The <tt>:include_js => true</tt> option appends <tt>javascripts/init.js</tt> in <script> tags.
    # Use this option when rendering a widget in an Ajax response.
    #
    def return_init_assets(widgets, options)
      # Render partials/_init.* (options[:include_js] will render javascripts/init.js in <script> tags)
      widgets.collect do |w|
        # We want widgets rendered from the partial to include first
        partial = w.render_init :partials, options
        css = w.render_init :css, options
        js  = w.render_init :js,  options
        if options[:include_js] && js && !js.empty?
          partial + "\n<script type='text/javascript'>\n#{js}\n</script>"
        else
          @assets.stylesheets do
            css
          end unless css.empty?
          @assets.javascripts do
            js
          end unless js.empty?
          partial
        end
      end
    end
    
    private
    
    # Returns an array of related paths based on a single widget path.
    #
    # ==== Example
    #   related_paths([ :some, :widget ])
    #   # => [ 'some', 'widget', 'some/widget' ]
    #
    # Options are merged based on the order of the array that <tt>related_paths</tt> returns:
    #   app/widgets/some/options.rb         # { :option1 => true, :option2 => false }
    #   app/widgets/widget/options.rb       # { :option1 => false }
    #   app/widgets/some/widget/options.rb  # { :option2 => true }
    #
    # Sequentially merging the options in this example produces <tt>{ :option1 => false, :option2 => true }</tt>.
    #
    # Assets are also included and rendered (init files) in the order of the <tt>related_paths</tt> array.
    #
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
  end
  
end