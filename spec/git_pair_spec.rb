require 'pivotal_git_scripts/git_pair'

describe PivotalGitScripts::GitPair::Runner do
  let(:runner) { described_class.new }

  describe 'set_git_config' do
    it 'calls git config with pairs in the options' do
      runner.should_receive(:system).with('git config user.foo "bar baz"')

      runner.set_git_config('', 'foo' => 'bar baz')
    end

    it 'can unset git config options' do
      runner.should_receive(:system).with('git config --unset user.foo')

      runner.set_git_config('', 'foo' => nil)
    end

    it 'can handle multiple pairs in a hash' do
      runner.should_receive(:system).with('git config --unset user.remove')
      runner.should_receive(:system).with('git config user.ten "10"')

      runner.set_git_config('', 'remove' => nil, 'ten' => '10')
    end

    it 'supports a global option' do
      runner.should_receive(:system).with('git config --global user.foo "bar baz"')

      runner.set_git_config(' --global', 'foo' => 'bar baz')
    end
  end
end
