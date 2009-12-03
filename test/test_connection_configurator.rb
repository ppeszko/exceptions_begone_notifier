require "test_helper"

class TestConnectionConfigurator < Test::Unit::TestCase
  def setup
    ExceptionsBegone::ConnectionConfigurator.instance_variable_set("@global_connection", nil)
  end

  def test_build_should_return_a_connection_cofigurator_with_default_settings
    conn_conf = ExceptionsBegone::ConnectionConfigurator.build
    assert_equal "127.0.0.1", conn_conf.host
  end
end