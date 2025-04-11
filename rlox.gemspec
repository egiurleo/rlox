Gem::Specification.new do |s|
  s.name                  = 'rlox'
  s.version               = '0.0.1'
  s.summary               = 'A Ruby lox interpreter'
  s.description           = "An implementation of Crafting Interpreter's jlox tree-walk interpreter, written in Ruby"
  s.authors               = ['Emily Samp']
  s.homepage              = 'https://github.com/emilysamp/rlox'
  s.files                 = ['lib/rlox.rb']
  s.license               = 'MIT'
  s.required_ruby_version = '3.4'
  s.metadata              = { 'rubygems_mfa_required' => 'true' }
  s.bindir                = "exe"
end
