require 'pty'

module SafePty
  # Wraps the PTY.spawn() call, wait until the process completes.
  # Also catch sexceptions that might be raised
  # See also https://www.omniref.com/ruby/gems/shell_test/0.5.0/files/lib/shell_test/shell_methods/utils.rb
  def self.spawn(command, &_block)
    PTY.spawn(command) do |r, w, p|
      begin
        yield r, w, p
      # if the process has closed, ruby might raise an exception if we try
      # to do I/O on a closed stream. This behavior is platform specific
      rescue Errno::EIO
      ensure
        begin
          Process.wait p
        # The process might have exited.
        # This behavior is also ruby version dependent.
        rescue Errno::ECHILD, PTY::ChildExited
        end
      end
    end
    $?.exitstatus
  end
end
