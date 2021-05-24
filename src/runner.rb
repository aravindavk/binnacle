require "open3"

module BinnacleTestsRunner
  @@dry_run = false
  @@tests_count = 0
  @@node = "local"
  @@remote_plugin = "ssh"

  # Only for getting the number of tests
  def self.dry_run?
    @@dry_run
  end

  # Set the dry run flag
  def self.dry_run=(val)
    @@dry_run = val
  end

  # Set node
  def self.node=(node)
    @@node = node
  end

  # Remote plugin ssh or docker
  def self.remote_plugin=(plugin)
    @@remote_plugin = plugin
  end

  def self.node
    @@node
  end

  def self.remote_plugin
    @@remote_plugin
  end

  def self.inc_counter
    @@tests_count += 1
  end

  def self.tests_count
    @@tests_count
  end

  # If node is not local then add respective prefix
  # to ssh or docker exec
  # TODO: support more options for ssh, like port and key
  def self.full_cmd(cmd)
    return cmd if @@node == "local"

    if @@remote_plugin == "ssh"
      "ssh #{@@node} /bin/bash -c '#{cmd}'"
    elsif @@remote_plugin == "docker"
      "docker exec -i #{@@node} /bin/bash -c '#{cmd}'"
    else
      cmd
    end
  end

  # Execute the command and return the status
  # TODO: Handle Timeout
  def self.execute(cmd)
    begin
      out, err, status = Open3.capture3(self.full_cmd(cmd))
      ret = status.exitstatus
    rescue Exception
      out, err, ret = ["", "Unknown command", -1]
    end

    [ret, out, err]
  end

  def self.print_test_state(ok_msg, test_id, msg)
    printf("%-6s %3d - %s\n", ok_msg, test_id, msg)
  end

  def self.OK_NOT_OK(cmd, ok, diagnostic=nil)
    out_desc = "node=#{@@node} cmd=\"#{cmd}\""
    puts "# #{diagnostic.split("\n").join("\n# ")}" if !diagnostic.nil?

    ok_msg = ok ? "ok" : "not ok"
    self.print_test_state(ok_msg, self.tests_count, out_desc)
  end

  def self.OK(cmd, diagnostic=nil)
    OK_NOT_OK(cmd, true, diagnostic)
  end

  def self.NOT_OK(cmd, diagnostic=nil)
    OK_NOT_OK(cmd, false, diagnostic)
  end

  def self.CMD_OK_NOT_OK(cmd, ret, out, err, expect_ret = 0)
    out_desc = "node=#{@@node} cmd=\"#{cmd}\""
    out_desc += " expect_ret=#{expect_ret}" if expect_ret != 0

    if ret == expect_ret
      self.print_test_state("ok", self.tests_count, out_desc)
    else
      puts "# #{err.split("\n").join("\n# ")}"
      self.print_test_state("not ok", self.tests_count, out_desc)
    end
  end
end
