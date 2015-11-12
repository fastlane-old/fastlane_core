require 'fastlane_core/update_checker/changelog'

release_json_file = "spec/responses/fastlane_releases.json"

RSpec.configure do |config|
  config.before(:each) do
    stub_request(:get, FastlaneCore::Changelog.generate_gem_releases_url("fastlane")).
      with(:headers => {'Host'=>'api.github.com:443', 'User-Agent'=>'excon/0.45.4'}).
      to_return(status: 200, body: File.read(release_json_file), headers: {})
  end
end

def with_captured_stdout
  begin
    old_stdout = $stdout
    $stdout = StringIO.new('','w')
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end

describe FastlaneCore do
  describe FastlaneCore::Changelog do
    describe "show_changes" do
      it "should display changes for each release" do
        captured_stdout = with_captured_stdout do
          FastlaneCore::Changelog.show_changes('fastlane', "1.38.0")
        end
        expected_output =<<-CHANGELOG
\n\e[32m1.39.0 New Actions and Features\e[0m\n- Added new `copy_artifacts` action to copy build artifacts into a separate directory\r\n- Added new `appetize` action to upload your app to a simulator available in your web browser\r\n- Added new `appledoc` integration\r\n- Added new `skip_clean` option to `reset_git_repo` action\r\n- Updated [.gitignore](https://github.com/fastlane/fastlane/blob/master/docs/Gitignore.md) documentation\r\n- Improved `clean_build_artifacts` action\r\n- Updated `spaceship` to work with the new iTunes Connect login architecture\r\n\r\nSpecial thanks to @alexmx, @ML, @giginet, @marcelofabri, @xfreebird, @lmirosevic for contributing :+1:\r\n\r\n**Examples:**\r\n\r\n```ruby\r\n# Move our artifacts to a safe location so TeamCity can pick them up\r\ncopy_artifacts(\r\n  target_path: 'artifacts',\r\n  artifacts: ['*.cer', '*.mobileprovision', '*.ipa', '*.dSYM.zip']\r\n)\r\n\r\n# Reset the git repo to a clean state, but leave our artifacts in place\r\nreset_git_repo(\r\n  exclude: 'artifacts'\r\n)\r\n```\r\n\r\n```ruby\r\nappledoc(\r\n  project_name: \"MyProjectName\",\r\n  project_company: \"Company Name\",\r\n  input: \"MyProjectSources\",\r\n  ignore: [\r\n    'ignore/path/1',\r\n    'ingore/path/2'\r\n  ],\r\n  options: \"--keep-intermediate-files --search-undocumented-doc\",\r\n  warnings: \"--warn-missing-output-path --warn-missing-company-id\"\r\n)\r\n```\n\n\e[32m1.38.1 Fixed .env\e[0m\n- Fixed not looking for `.env` files in subdirectories\n- Updated `sigh` dependency\n\e[32m\nUpdate using 'sudo gem update fastlane'\e[0m
CHANGELOG
        expect(captured_stdout).to eq expected_output
      end
    end
  end
end
