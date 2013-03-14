require 'pivotal_git_scripts/git_pair'

describe PivotalGitScripts::GitPair::Runner do
  let(:runner) { described_class.new }

  describe 'set_git_config' do
    it 'calls git config with pairs in the options' do
      runner.should_receive(:system).with('git config user.foo "bar baz"')

      runner.set_git_config(false, 'foo' => 'bar baz')
    end

    it 'can unset git config options' do
      runner.should_receive(:system).with('git config --unset user.foo')

      runner.set_git_config(false, 'foo' => nil)
    end

    it 'can handle multiple pairs in a hash' do
      runner.should_receive(:system).with('git config --unset user.remove')
      runner.should_receive(:system).with('git config user.ten "10"')

      runner.set_git_config(false, 'remove' => nil, 'ten' => '10')
    end

    it 'supports a global option' do
      runner.should_receive(:system).with('git config --global user.foo "bar baz"')

      runner.set_git_config(true, 'foo' => 'bar baz')
    end
  end

  describe 'read_author_info_from_config' do
    it 'maps from the initials to the full name' do
      config = {
        'pairs' => {
          'aa' => 'An Aardvark',
          'tt' => 'The Turtle'
        }
      }

      names = runner.read_author_info_from_config(config, ['aa', 'tt'])
      names.should =~ ['An Aardvark', 'The Turtle']
    end

    it 'exits when initials cannot be found' do
      expect {
        runner.read_author_info_from_config({"pairs" => {}}, ['aa'])
      }.to raise_error(PivotalGitScripts::GitPair::GitPairException)
    end
  end
end
