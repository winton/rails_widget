Gem::Specification.new do |s|
  s.name    = 'rails_widget'
  s.version = '1.1'
  s.date    = '2008-11-08'
  
  s.summary     = "Allows you to group your client-side assets into distributable widgets"
  s.description = "Allows you to group your client-side assets into distributable widgets"
  
  s.author   = 'Winton Welsh'
  s.email    = 'mail@wintoni.us'
  s.homepage = 'http://github.com/winton/rails_widget'
  
  s.has_rdoc = true
  
  s.files = Dir[*%w(
    init.rb
    lib/*
    lib/**/*
    MIT-LICENSE
    README.markdown
  )]
end
