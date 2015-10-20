describe FastlaneCore do
  describe FastlaneCore::PrintTable do
    before do
      @options = [
        FastlaneCore::ConfigItem.new(key: :cert_name,
                                env_name: "SIGH_PROVISIONING_PROFILE_NAME",
                             description: "Set the profile name",
                           default_value: "production_default",
                            verify_block: nil),
        FastlaneCore::ConfigItem.new(key: :output,
                                env_name: "SIGH_OUTPUT_PATH",
                             description: "Directory in which the profile should be stored",
                           default_value: ".",
                            verify_block: proc do |value|
                              raise "Could not find output directory '#{value}'".red unless File.exist?(value)
                            end),
        FastlaneCore::ConfigItem.new(key: :a_hash,
                                     description: "Metadata: A hash",
                                     optional: true,
                                     is_string: false)
      ]
      @values = {
        cert_name: "asdf",
        output: "..",
        a_hash: {}
      }
      @config = FastlaneCore::Configuration.create(@options, @values)
    end

    it "supports nil config" do
      value = FastlaneCore::PrintTable.print_values
      expect(value).to eq({ rows: [] })
    end

    it "prints out all the information in a nice table" do
      title = "Custom Title"

      value = FastlaneCore::PrintTable.print_values(config: @config, title: title)
      expect(value[:title]).to eq(title.green)
      expect(value[:rows]).to eq([['cert_name', "asdf"], ['output', '..']])
    end

    it "supports hide_keys property with symbols" do
      value = FastlaneCore::PrintTable.print_values(config: @config, hide_keys: [:cert_name])
      expect(value[:rows]).to eq([['output', '..']])
    end

    it "supports hide_keys property with strings" do
      value = FastlaneCore::PrintTable.print_values(config: @config, hide_keys: ['cert_name'])
      expect(value[:rows]).to eq([['output', '..']])
    end

    it "recurses over hashes" do
      @config[:a_hash][:foo] = 'bar'
      @config[:a_hash][:bar] = { foo: 'bar' }
      value = FastlaneCore::PrintTable.print_values(config: @config, hide_keys: [:cert_name])
      expect(value[:rows]).to eq([['output', '..'], ['a_hash.foo', 'bar'], ['a_hash.bar.foo', 'bar']])
    end

    it "supports hide_keys property in hashes" do
      @config[:a_hash][:foo] = 'bar'
      @config[:a_hash][:bar] = { foo: 'bar' }
      value = FastlaneCore::PrintTable.print_values(config: @config, hide_keys: [:cert_name, 'a_hash.foo', 'a_hash.bar.foo'])
      expect(value[:rows]).to eq([['output', '..']])
    end

    # This isn't implemented as using style in 1.4.5 breaks terminal
    # see https://github.com/tj/terminal-table/issues/23
    it "breaks down long lines" do
      long_breakable_text = 'bar ' * 40
      @config[:cert_name] = long_breakable_text
      value = FastlaneCore::PrintTable.print_values(config: @config, hide_keys: [:output])
      expect(value[:rows]).to eq([['cert_name', long_breakable_text]])
      # expect(value[:style]).to eq({width: 80})
    end
  end
end
