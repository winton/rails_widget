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
    @assets ||= Assets.new binding, controller
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
    @assets ||= Assets.new binding, controller
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
  def templates(*paths, &block)
    @assets ||= Assets.new binding, controller
    @assets.templates *paths, &block
  end
  
  class Assets
    attr :assets, true
    attr :block,  true
    attr :item,   true
    
    def initialize(bind, controller)
      @bind = bind
      @controller = controller
      @assets = {}
    end
  
    def javascripts(*paths, &block)
      add_assets :javascripts, paths, &block
    end
  
    def stylesheets(*paths, &block)
      add_assets :stylesheets, paths, &block
    end
  
    def templates(*paths, &block)
      add_assets :templates, paths, &block
    end
    
    private
    
    def add_assets(type, paths, &block)
      @assets[type] ||= []
      options = paths.extract_options! unless type == :templates
      
      if paths.empty?
        paths = nil 
      else
        paths.flatten!
        paths.push options unless type == :templates
        @assets[type].push paths
      end
      
      if block
        @block  = block
        capture = eval "capture(&@assets.block)", @bind
        if type == :templates && !paths.empty?
          @assets[type].last.push capture
        else
          @assets[type].push capture
        end
      end
    
      if !paths && !block
        @assets[type].uniq!
        remove_dups @assets[type]
        unless type == :templates
          @assets[type].collect! { |a| a[0].respond_to?(:keys) ? nil : a }
          @assets[type].compact!
        end
        
        css = []
        js  = []
        assets = @assets[type].collect do |item|
          if item.respond_to?(:pop)
            @item = item
            case type
            when :javascripts
              eval "javascript_include_tag *@assets.item", @bind
            when :stylesheets
              eval "stylesheet_link_tag    *@assets.item", @bind
            when :templates
              item.each_index do |x|
                @item = item[x]
                next if @item.respond_to?(:gsub)
                n = item[x + 1]
                @item[:body] = n if n.respond_to?(:gsub)
                eval "textarea_template @assets.item", @bind
              end
            end + "\n"
          else
            case type
            when :javascripts
              js.push(item)  unless item.blank?
              nil
            when :stylesheets
              css.push(item) unless item.blank?
              nil
            when :templates
              @item = { :body => item }
              eval "textarea_template @assets.item", @bind
            else
              item
            end
          end
        end.compact
        if type == :javascripts
          assets.join + "<script type='text/javascript'>\n#{js.join "\n"}\n</script>"
        elsif type == :javascripts
          assets.join + "<style type='text/css'>\n#{css.join "\n"}\n</style>"
        else
          assets.join
        end
      end
    end
    
    def remove_dups(arr, list=[])
      arr.dup.each do |a|
        if a.respond_to?(:keys)
          next
        elsif a.respond_to?(:pop)
          remove_dups a, list
        else
          if list.include?(a) || a.blank?
            arr.delete_at arr.rindex(a)
          else
            list << a
          end
        end
      end
    end
  
    def textarea_template(options)
      id = 'template' + (options[:id] ? "_#{options[:id]}" : '')
      if options[:body]
        body = options[:body]
      elsif options[:partial]
        body = @controller.render_to_string :partial => options[:partial], :locals => options[:locals]
      end
      "<textarea id='#{id}' style='display:none'>\n#{body}\n</textarea>" 
    end
  end
end