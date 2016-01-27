describe FastlaneCore do
  describe FastlaneCore::CommandExecutor do
    describe "which" do
      require 'tempfile'

      it "does not find commands which are not on the PATH" do
        expect(FastlaneCore::CommandExecutor.which('not_a_real_command')).to be_nil
      end

      it "finds commands without extensions which are on the PATH" do
        Tempfile.create('foobarbaz') do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f)

          with_env_values('PATH' => temp_dir) do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to eq(f.path)
          end
        end
      end

      it "finds commands with known extensions which are on the PATH" do
        Tempfile.create(['foobarbaz', '.exe']) do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f, '.exe')

          with_env_values('PATH' => temp_dir, 'PATHEXT' => '.exe') do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to eq(f.path)
          end
        end
      end

      it "does not find commands with unknown extensions which are on the PATH" do
        Tempfile.create(['foobarbaz', '.exe']) do |f|
          File.chmod(0777, f)

          temp_dir = File.dirname(f)
          temp_cmd = File.basename(f, '.exe')

          with_env_values('PATH' => temp_dir, 'PATHEXT' => '') do
            expect(FastlaneCore::CommandExecutor.which(temp_cmd)).to be_nil
          end
        end
      end
    end
    describe "execute" do
      it "raise error upon exit status failure" do
        expect do
          output = FastlaneCore::CommandExecutor.execute(command: "ruby -e 'exit 1'")
        end.to raise_error(RuntimeError, /Exit status: 1/)
      end

      it "captures error output upon exit status failure" do
        captured_output = []
        error = proc do |l|
          captured_output << l
        end
        output = FastlaneCore::CommandExecutor.execute(command: "ruby -e 'exit 1'", error: error)
        expect(captured_output).to eq(["Exit status: 1".red])
        expect(output).to eq("Exit status: 1".red)
      end
    end
  end
end
