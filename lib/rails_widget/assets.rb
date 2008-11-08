module RailsWidget #:doc:
  
  def javascripts(*paths, &block)
    @assets ||= Assets.new binding, controller
    @assets.javascripts *paths, &block
  end

  def stylesheets(*paths, &block)
    @assets ||= Assets.new binding, controller
    @assets.stylesheets *paths, &block
  end

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
      paths.each do |path|
        add_assets :templates, path, &block
      end
      add_assets(:templates, paths, &block) if paths.empty?
    end
    
    private
    
    def add_assets(type, paths, &block)
      options = paths.extract_options!
      paths.flatten! unless type == :templates
      
      @assets[type] ||= []
    
      paths = nil if paths.empty?
    
      paths.push(options) if paths
      @assets[type].push(paths) if paths
      if block
        @block = block
        @assets[type].push eval("capture(&@assets.block)", @bind)
      end
    
      if !paths && !block
        #logger.info type.inspect
        #logger.info 'LAYOUT ' + @layout_assets[type].inspect
        #logger.info @assets[type].inspect
      
        @assets[type].uniq!
        remove_dups @assets[type]
        @assets[type].collect! { |a| a[0].respond_to?(:keys) ? nil : a }
        @assets[type].compact!
      
        js = []
        assets = @assets[type].collect do |item|
          if item.respond_to?(:pop)
            @item = item
            case type
            when :javascripts
              eval "javascript_include_tag *@assets.item", @bind
            when :stylesheets
              eval "stylesheet_link_tag    *@assets.item", @bind
            when :templates
              eval "textarea_template @assets.item[0], @assets.item[1], @assets.item[2]", @bind
            end + "\n"
          else
            case type
            when :javascripts
              js.push(item) unless item.blank?
              nil
            else
              item
            end
          end
        end.compact
        if type == :javascripts
          assets.join + "<script type='text/javascript'>\n#{js.join "\n"}\n</script>"
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
  
    def textarea_template(id, path=nil, locals={})
      @controller.render_to_string(:partial => 'app_helpers/template/textarea', :locals => {
        :id => id,
        :body => @controller.render_to_string(:partial => path, :locals => locals)
      })
    end
  end
end