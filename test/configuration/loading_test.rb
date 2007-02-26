$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'test/unit'
require 'mocha'
require 'capistrano/configuration/loading'

class ConfigurationLoadingTest < Test::Unit::TestCase
  class MockConfig
    include Capistrano::Configuration::Loading

    attr_accessor :ping

    def ping!(value)
      @ping = value
    end
  end

  def setup
    @config = MockConfig.new
  end

  def teardown
    MockConfig.instance = nil
    $".delete "#{File.dirname(__FILE__)}/../fixtures/custom.rb"
  end

  def test_initialize_sets_load_paths
    assert @config.load_paths.include?(".")
    assert @config.load_paths.detect { |v| v =~ /capistrano\/recipes$/ }
  end

  def test_load_with_options_and_block_should_raise_argument_error
    assert_raises(ArgumentError) do
      @config.load(:string => "foo") { something }
    end
  end

  def test_load_with_arguments_and_block_should_raise_argument_error
    assert_raises(ArgumentError) do
      @config.load("foo") { something }
    end
  end

  def test_load_from_string_should_eval_in_config_scope
    @config.load :string => "ping! :here"
    assert_equal :here, @config.ping
  end

  def test_load_from_file_shoudld_respect_load_path
    File.stubs(:file?).returns(false)
    File.stubs(:file?).with("custom/path/for/file.rb").returns(true)
    File.stubs(:read).with("custom/path/for/file.rb").returns("ping! :here")

    @config.load_paths << "custom/path/for"
    @config.load :file => "file.rb"

    assert_equal :here, @config.ping
  end

  def test_load_from_file_should_respect_load_path_and_appends_rb
    File.stubs(:file?).returns(false)
    File.stubs(:file?).with("custom/path/for/file.rb").returns(true)
    File.stubs(:read).with("custom/path/for/file.rb").returns("ping! :here")

    @config.load_paths << "custom/path/for"
    @config.load :file => "file"

    assert_equal :here, @config.ping
  end

  def test_load_from_file_should_raise_load_error_if_file_cannot_be_found
    File.stubs(:file?).returns(false)
    assert_raises(LoadError) do
      @config.load :file => "file"
    end
  end

  def test_load_from_proc_should_eval_proc_in_config_scope
    @config.load :proc => Proc.new { ping! :here }
    assert_equal :here, @config.ping
  end

  def test_load_with_block_should_treat_block_as_proc_parameter
    @config.load { ping! :here }
    assert_equal :here, @config.ping
  end

  def test_load_with_unrecognized_option_should_raise_argument_error
    assert_raises(ArgumentError) do
      @config.load :url => "http://www.load-this.test"
    end
  end

  def test_load_with_arguments_should_treat_arguments_as_files
    File.stubs(:file?).returns(false)
    File.stubs(:file?).with("./first.rb").returns(true)
    File.stubs(:file?).with("./second.rb").returns(true)
    File.stubs(:read).with("./first.rb").returns("ping! 'this'")
    File.stubs(:read).with("./second.rb").returns("ping << 'that'")
    assert_nothing_raised { @config.load "first", "second" }
    assert_equal "thisthat", @config.ping
  end

  def test_require_from_config_should_load_file_in_config_scope
    assert_nothing_raised do
      @config.require "#{File.dirname(__FILE__)}/../fixtures/custom"
    end
    assert_equal :custom, @config.ping
  end

  def test_require_without_config_should_raise_load_error
    assert_raises(LoadError) do
      require "#{File.dirname(__FILE__)}/../fixtures/custom"
    end
  end
end