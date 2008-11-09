# RailsWidget allows you to group your client-side assets into distributable "widgets"
#
# * Attach assets and render partials with a single <tt>widget</tt> call
# * Configure widgets via an <tt>options.rb</tt> file
# * Supports flash, images, javascripts, partials, stylesheets, and textarea templates
#
# == Example
# === What is a widget?
# Each directory in <tt>app/widgets</tt> is considered a widget. Let's make a widget called <tt>alert</tt>.
#
#   app/
#     widgets/
#       alert/
#         options.rb
#         flash/
#         images/
#         javascripts/
#           alert.js
#           init.js
#         partials/
#           _init.html.erb
#         stylesheets/
#           init.css
#           style.css
#         templates/
#
# <b>Init</b> files are rendered directly into the layout (inline, dynamically generated).
#
# ==== options.rb
#   { :id => 'alert', :message => 'Hello world!', :color => 'red' }
#
# ==== javascripts/alert.js
#   function alertWidget(options) {
#     alert(options.message);
#   }
#
# ==== javascripts/init.js
#   alertWidget(<%= options.to_json %>);
#
#
# ==== partials/_init.html.erb
#   <div id="<%= id %>" class="alert">
#     You just got alerted.
#   </div>
#
# ==== stylesheets/init.css
#   #<%= id %> { color:<%= color %>; }
#
# ==== stylesheets/style.css
#   .alert { font-size:18px; }
#
# === Layout view
#   <html>
#     <head>
#       <%= javascripts %>
#       <%= stylesheets %>
#     </head>
#     <body>
#       <%= yield %>
#     </body>
#   </html>
#
# === Action view
#   <%= widget :alert, :id => 'alert1', :color => 'blue' %>
#   <%= widget :alert, :id => 'alert2' %>
#
# === Resulting HTML
#   <html>
#     <head>
#       <script src="/javascripts/widgets/alert/alert.js?1220593492" type="text/javascript"></script>
#       <script type='text/javascript'>
#         alertWidget({ id: 'alert', message: 'Hello world!', color: 'red' });
#       </script>
#       <link href="/stylesheets/widgets/alert/style.css?1220593492" media="screen" rel="stylesheet" type="text/css" />
#       <style type="text/css">
#         #alert1 { color:blue; }
#         #alert2 { color:red; }
#       </style>
#     </head>
#     <body>
#       <div id="alert1" class="alert">
#         You just got alerted.
#       </div>
#       <div id="alert2" class="alert">
#         You just got alerted.
#       </div>
#     </body>
#   </html>
#
# == Inheritance
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