require 'pivotal_git_scripts/git_pair'

module UseCases
  class GitPair
    class << self
      def apply(opts={})
        git    = opts[:git] || fail("You need to supply the :git port")
        config = opts[:config] || fail("You need to supply :config. (The current git pair settings.)")

        #author_names, email_ids = extract_author_names_and_email_ids_from_config(config, initials)
        authors = pair_names(config.map{|c| c[:name]})
        #git_config              = {:name => authors,  :initials => initials.sort.join(" ")}

        git.config(:author_name => authors)
      end

      private

      def pair_names(author_names) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
        [author_names[0..-2].join(", "), author_names.last].reject(&:empty?).join(" and ")
      end
    end
  end
end

describe "\`git pair rb bb\`" do
  it 'sets author.name to combination of authors' do
    git = spy("represents the current git repo")

    config = [
      {:initials => 'bb', :name => "Ben Biddington", :email => "ben.biddington@aol.com"},
      {:initials => 'rf', :name => "Richard Bizzness", :email => "ricky.bizzness@eire.com"}
    ]
    
    UseCases::GitPair.apply(:initials => ['bb' 'rf'], :git => git, :config => config)

    expect(git).to have_received(:config).with({
      :author_name => "Ben Biddington and Richard Bizzness"})
  end
  
  describe 'that you may configure it such that \`git pair\` sets auther email, too'
end

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
