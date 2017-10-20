require 'test_helper'
require 'scout_apm/slow_transaction'
require 'scout_apm/metric_meta'
require 'scout_apm/metric_stats'
require 'scout_apm/context'
require 'scout_apm/store'

require 'fileutils'
class LayawayTest < Minitest::Test
  def test_directory_uses_DATA_FILE_option
    FileUtils.mkdir_p '/tmp/scout_apm_test/data_file_option'
    config = make_fake_config("data_file" => "/tmp/scout_apm_test/data_file_option")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    layaway = ScoutApm::Layaway.new(context)

    assert_equal Pathname.new("/tmp/scout_apm_test/data_file_option"), layaway.directory
  end

  def test_directory_looks_for_root_slash_tmp
    FileUtils.mkdir_p '/tmp/scout_apm_test/tmp'
    config = make_fake_config({})
    env = make_fake_environment(:root => "/tmp/scout_apm_test")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config; c.environment = env }

    assert_equal Pathname.new("/tmp/scout_apm_test/tmp"), ScoutApm::Layaway.new(context).directory
  end

  def test_layaway_file_limit_prevents_new_writes
    FileUtils.mkdir_p '/tmp/scout_apm_test/layaway_limit'
    config = make_fake_config("data_file" => "/tmp/scout_apm_test/layaway_limit")
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    layaway = ScoutApm::Layaway.new(context)
    layaway.delete_files_for(:all)

    context = ScoutApm::AgentContext.new
    current_time = Time.now.utc
    current_rp = ScoutApm::StoreReportingPeriod.new(current_time, context)
    stale_rp = ScoutApm::StoreReportingPeriod.new(current_time - current_time.sec - 120, context)

    # layaway.write_reporting_period returns nil on successful write
    # It should probably be changed to return true or the number of bytes written
    assert_nil layaway.write_reporting_period(stale_rp, 1)

    # layaway.write_reporting_period returns an explicit false class on failure
    assert layaway.write_reporting_period(current_rp, 1).is_a?(FalseClass)

    layaway.delete_files_for(:all)
  end
end
