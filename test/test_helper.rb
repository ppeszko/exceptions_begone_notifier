require 'test/unit'
require 'mocha'

begin
  require 'redgreen' unless ENV['TM_FILENAME']
rescue LoadError
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'exceptions_begone_notifier'

class Test::Unit::TestCase
end
