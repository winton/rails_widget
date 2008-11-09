# RailsWidget allows you to group your client-side assets into distributable "widgets".
#
# * Include assets and render partials into your layout with a single <tt>widget</tt> call
# * Share a common options hash between all of your renderable assets
# * Widgets are inheritable
# * Also supports flash, images, javascripts, stylesheets, and textarea template (jst) assets
#
# Install your first widget <http://github.com/winton/rails_widget/wikis>.
#
# More documentation can be found on our github wiki <http://github.com/winton/rails_widget/wikis>.
#
module RailsWidget
end

Dir[File.expand_path('*/*.rb', File.dirname(__FILE__))].each do |f|
  require [ File.dirname(f), File.basename(f, '.rb') ].join('/')
end

ActionView::Base.send :include, RailsWidget
ActionController::Base.send :include, RailsWidget
ActionController::Base.view_paths += [ RAILS_ROOT + '/app/widgets' ]

# :main:RailsWidget