Dir[File.expand_path('*/*.rb', File.dirname(__FILE__))].each do |f|
  require [ File.dirname(f), File.basename(f, '.rb') ].join('/')
end

ActionView::Base.send :include, WidgetHelpers
ActionController::Base.send :include, WidgetHelpers
ActionController::Base.view_paths += [ RAILS_ROOT + '/app/widgets' ]