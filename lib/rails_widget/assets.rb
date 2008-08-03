module WidgetHelpers
  
  def default_javascript
    "#{params[:controller]}/#{params[:action]}"
  end
  
  def default_stylesheet
    "#{params[:controller]}/#{params[:action]}"
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
  
  def textarea_template(id, path=nil, locals={})
    controller.render_to_string(:partial => 'app_helpers/template/textarea', :locals => {
      :id => id,
      :body => controller.render_to_string(:partial => path, :locals => locals)
    })
  end
  
private

  def add_assets(type, paths, &block)
    options = paths.extract_options!
    paths.flatten! unless type == :templates
    
    @assets ||= {}
    @assets[type] ||= []
    @layout_assets ||= {}
    @layout_assets[type] ||= []
    
    paths = nil if paths.empty?
    
    if options[:layout]
      options.delete :layout
      paths.push(options) if paths
      @layout_assets[type].push(paths          ) if paths
      @layout_assets[type].push(capture(&block)) if block
    else
      paths.push(options) if paths
      @assets[type].push(paths          ) if paths
      @assets[type].push(capture(&block)) if block
    end
    
    if !paths && !block
      #logger.info type.inspect
      #logger.info 'LAYOUT ' + @layout_assets[type].inspect
      #logger.info @assets[type].inspect
      
      @assets[type] = @layout_assets[type] + @assets[type]
      
      @assets[type].uniq!
      remove_dups @assets[type]
      @assets[type].collect! { |a| a[0].respond_to?(:keys) ? nil : a }
      @assets[type].compact!
      
      js = []
      assets = @assets[type].collect do |item|
        if item.respond_to?(:pop)
          case type
          when :javascripts
            javascript_include_tag *item
          when :stylesheets
            stylesheet_link_tag *item
          when :templates
            textarea_template item[0], item[1], item[2]
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
  
end