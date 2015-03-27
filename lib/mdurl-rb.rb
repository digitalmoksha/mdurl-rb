# encoding: utf-8

if defined?(Motion::Project::Config)
  
  lib_dir_path = File.dirname(File.expand_path(__FILE__))
  Motion::Project::App.setup do |app|
    app.files.unshift(Dir.glob(File.join(lib_dir_path, "mdurl-rb/**/*.rb")))
  end

else
  
  require 'mdurl-rb/parse'
  require 'mdurl-rb/format'
  require 'mdurl-rb/encode'
  require 'mdurl-rb/decode'
  
end