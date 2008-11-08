Dir[File.expand_path('*/*.rb', File.dirname(__FILE__))].each do |f|
  require [ File.dirname(f), File.basename(f, '.rb') ].join('/')
end

ActionView::Base.send :include, RailsWidget
ActionController::Base.send :include, RailsWidget
ActionController::Base.view_paths += [ RAILS_ROOT + '/app/widgets' ]