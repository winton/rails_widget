require 'rails_widget'

ActionView::Base.send :include, WidgetHelpers
ActionController::Base.send :include, WidgetHelpers
ActionController::Base.view_paths += [ RAILS_ROOT + '/app/widgets' ]