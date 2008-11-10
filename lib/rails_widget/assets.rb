module RailsWidget
  
  # Adds or renders javascript assets based on whether parameters are given or not.
  #
  # ==== Layout view
  #   <html>
  #     <head>
  #       <%= javascripts %>
  #     </head>
  #     <%= yield %>
  #   </html>
  #
  # ==== Action view
  #   <% javascripts 'script1', 'script2' do -%>
  #     alert('Hello world!');
  #   <% end -%>
  #   Content goes here.
  #
  # ==== Resulting HTML
  #   <html>
  #     <head>
  #       <script src="/javascripts/script1.js?1220593492" type="text/javascript"></script>
  #       <script src="/javascripts/script2.js?1220593492" type="text/javascript"></script>
  #       <script type='text/javascript'>
  #         alert('Hello world!');
  #       </script>
  #     </head>
  #     Content goes here.
  #   </html>
  #
  # Calling <tt>javascripts</tt> with path parameters or a script block will store the asset for later rendering.
  #
  # Calling <tt>javascripts</tt> without parameters renders the assets in the order they were added.
  #
  # The method accepts all options supported by <tt>javascript_include_tag</tt>.
  #
  def javascripts(*paths, &block)
    @assets ||= Assets.new binding, controller, logger
    @assets.javascripts *paths, &block
  end
  
  # Adds or renders stylesheet assets based on whether parameters are given or not.
  #
  # ==== Layout example
  #   <html>
  #     <head>
  #       <%= stylesheets %>
  #     </head>
  #     <%= yield %>
  #   </html>
  #
  # ==== Action example
  #   <% stylesheets 'style1', 'style2' -%>
  #   Content goes here.
  #
  # ==== Result
  #   <html>
  #     <head>
  #       <link href="/stylesheets/style1.css?1224923418" media="screen" rel="stylesheet" type="text/css" />
  #       <link href="/stylesheets/style2.css?1224923418" media="screen" rel="stylesheet" type="text/css" />
  #     </head>
  #     Content goes here.
  #   </html>
  #
  # Calling <tt>stylesheets</tt> with path parameters will store the asset for later rendering.
  #
  # Calling <tt>stylesheets</tt> without parameters renders the assets in the order they were added.
  #
  # The method accepts all options supported by <tt>stylesheet_link_tag</tt>.
  #
  def stylesheets(*paths, &block)
    @assets ||= Assets.new binding, controller, logger
    @assets.stylesheets *paths, &block
  end
  
  # Adds or renders textarea-based templates based on whether parameters are given or not.
  #
  # Use this with something like PURE <http://beebole.com/pure> or TrimPath's JST <http://trimpath.com>.
  #
  # ==== Layout example
  #   <html>
  #     <%= yield %>
  #     <%= templates %>
  #   </html>
  #
  # ==== Action example
  #   <% templates :id => 'myid', :partial => 'some_action/partial', :locals => { :x => 'Hello world' } -%>
  #   <% templates do -%>
  #     Template goes here.
  #   <% end -%>
  #   Content goes here.
  #
  # ==== Partial example (<tt>some_action/partial</tt>)
  #   <%= x %>!
  #
  # ==== Result
  #   <html>
  #     Content goes here.
  #     <textarea id='template_myid' style='display:none'>
  #       Hello world!
  #     </textarea>
  #     <textarea id='template' style='display:none'>
  #       Template goes here.
  #     </textarea>
  #   </html>
  #
  # Calling <tt>templates</tt> with path parameters or a block will store the asset for later rendering.
  #
  # Calling <tt>templates</tt> without parameters renders the assets in the order they were added.
  #
  def templates(*options, &block)
    @assets ||= Assets.new binding, controller, logger
    @assets.templates *options, &block
  end
  
  # Keeps track of assets added by the javascripts, stylesheets, and templates helpers.
  #
  class Assets
    attr :assets, true
    
    # This is used for outside access from eval calls.
    # Is there a better way to do this?
    #
    attr :block,   true
    attr :params,  true
    attr :options, true
    
    def initialize(bind, controller, logger)
      @assets = {}
      @bind = bind
      @controller = controller
      @logger = logger
    end
    
    # See <tt>javascripts (RailsWidget)</tt>.
    #
    def javascripts(*params, &block)
      add_assets :javascripts, params, &block
    end
    
    # See <tt>stylesheets (RailsWidget)</tt>.
    #
    def stylesheets(*params, &block)
      add_assets :stylesheets, params, &block
    end
    
    # See <tt>templates (RailsWidget)</tt>.
    #
    def templates(*params, &block)
      add_assets :templates, params, &block
    end
    
    private
    
    # Either adds assets or returns layout HTML.
    #
    # Assets are added if a parameter or block is given.
    #
    # HTML is returned for the specified asset type if no parameters or block given.
    #
    def add_assets(type, params, &block) #:doc:
      options = params.extract_options! unless type == :templates
      capture = block_to_string &block
      asset   = delete_if_empty(:options => options, :params => params, :capture => capture)
      if asset.empty?
        remove_dups :javascripts, :params
        remove_dups :stylesheets, :params, :capture
        remove_dups :templates,   :params, :capture
        captures = []
        tags     = []
        @assets[type].each do |item|
          @capture = item[:capture]
          @params  = item[:params]
          @options = item[:options]
          case type
          when :javascripts
            captures.push(@capture) if @capture
            tags.push(eval("javascript_include_tag *[ @assets.params, @assets.options ].flatten.compact", @bind)) if @params
          when :stylesheets
            captures.push(@capture) if @capture
            tags.push(eval("stylesheet_link_tag    *[ @assets.params, @assets.options ].flatten.compact", @bind)) if @params
          when :templates
            captures.push(textarea_template(@params.pop.merge(:body => @capture))) if @capture
            @params.each do |options|
              captures << textarea_template(options)
            end
          end
        end
        case type
        when :javascripts
          tags.join("\n") + (captures.empty? ? '' : "\n<script type='text/javascript'>\n#{captures.join "\n"}\n</script>")
        when :stylesheets
          tags.join("\n") + (captures.empty? ? '' : "\n<style type='text/css'>\n#{captures.join "\n"}\n</style>")
        when :templates
          captures.uniq.join "\n"
        end
      else
        @assets[type] ||= []
        @assets[type].push asset
      end
    end
    
    # Runs Rails' capture method on a block and returns the result.
    #
    def block_to_string(&block) #:doc:
      return nil unless block
      @block = block
      eval "capture(&@assets.block)", @bind
    end
    
    # Delete any keys that have nil, empty, or blank values.
    #
    def delete_if_empty(hash) #:doc:
      list = []
      hash.each { |key, value| list.push(key) if !value || value.empty? || value.blank? }
      list.each { |key|        hash.delete key }
      hash
    end
    
    # Removes duplicate asset values of a specific asset type and key.
    #
    def remove_dups(type, *keys) #:doc:
      asset = @assets[type]
      keys.each do |key|
        list = []
        asset.each do |a|
          if list.include?(a[key])
            a.delete key
          else
            list << a[key]
          end
        end
      end if asset
    end
    
    # See <tt>templates (RailsWidget)</tt>.
    #
    # Takes options from the templates call and makes HTML out of it.
    #
    def textarea_template(options) #:doc:
      id = 'template' + (options[:id] ? "_#{options[:id]}" : '')
      if options[:body]
        body = options[:body]
      elsif options[:partial]
        body = @controller.render_to_string :partial => options[:partial], :locals => options[:locals]
      end
      return nil unless body
      "<textarea id='#{id}' style='display:none'>\n#{body}\n</textarea>" 
    end
  end
end