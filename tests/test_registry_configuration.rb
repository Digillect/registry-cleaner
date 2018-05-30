require 'helper'

class RegistryConfigurationTests < Minitest::Test
  CONFIG = {
    'url' => 'https://registry.example.org',
    'username' => 'john_doe',
    'password' => '${PASSWORD}',
    'ignore' => %w[a/.+ b/c]
  }.freeze

  def test_id_and_hostname_are_set
    registry = DummyRegistry.new('registry.example.org', CONFIG)

    assert_equal(registry.id, 'registry.example.org')
    assert_equal(registry.hostname, 'registry.example.org/')
  end

  def test_config_value_with_value
    registry = DummyRegistry.new('registry.example.org', CONFIG)

    username = registry.get_config_value(CONFIG, 'username')

    assert_equal(username, 'john_doe')
  end

  def test_config_value_with_variable
    registry = DummyRegistry.new('registry.example.org', CONFIG)

    env = { 'PASSWORD' => 'secret' }

    Object.stub_const(:ENV, env) do
      password = registry.get_config_value(CONFIG, 'password')

      assert_equal(password, 'secret')
    end
  end

  class DummyRegistry < Registry
    def get_config_value(config, name, default = nil)
      config_value(config, name, default)
    end
  end
end
