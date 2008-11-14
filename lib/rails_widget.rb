# RailsWidget allows you to group your client-side assets into distributable "widgets".
#
# * Include assets and render partials to layout with a single <tt>widget</tt> call
# * Share a common options hash between all of your rendered assets
# * Supports flash, images, javascripts, stylesheets, and textarea template (jst) assets
# * Widgets can inherit
#
# You can also use it to organize your assets however you like (layout, action, etc).
#
# === Install
#
# From your Rails app:
#   script/plugin install git://github.com/winton/rails_widget.git
#
# === Getting started
#
# Visit the github wiki for more on installing and creating widgets.
#
# http://github.com/winton/rails_widget/wikis
#
module RailsWidget
end

Dir[File.expand_path('*/*.rb', File.dirname(__FILE__))].each do |f|
  require [ File.dirname(f), File.basename(f, '.rb') ].join('/')
end

ActionView::Base.send :include, RailsWidget
ActionController::Base.send :include, RailsWidget
ActionController::Base.view_paths += [ RAILS_ROOT + '/app/widgets' ]
Rails::Generator::Commands::Create.send :include, RailsWidget::Generator

# :main:RailsWidget