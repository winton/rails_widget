Gem::Specification.new do |s|
  s.name    = 'rails_widget'
  s.version = '1.0.1'
  s.date    = '2008-08-16'
  
  s.summary     = "A mini-framework for your client side Rails assets"
  s.description = "A mini-framework for your client side Rails assets"
  
  s.author   = 'Winton Welsh'
  s.email    = 'mail@wintoni.us'
  s.homepage = 'http://github.com/winton/rails_widget'
  
  s.has_rdoc = false
  
  s.files = Dir[*%w(
    init.rb
    lib/*
    lib/**/*
    MIT-LICENSE
    README.markdown
    tasks/*
  )]
end
