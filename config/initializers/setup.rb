Dir[Rails.root.join("lib/ext/**/*.rb")].each {|f| require f}
require 'plugins'