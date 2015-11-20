require 'pivotal_git_scripts/git_pair'

module UseCases
  class GitPair
    class << self
      def apply(opts={})
        git      = opts[:git]      || fail("You need to supply the :git port")
        config   = opts[:config]   || fail("You need to supply :config. (The current git pair settings.)")
        initials = opts[:initials] || []
        global   = opts[:global]   || config['global'] || false
        
        if initials.any?
          author_names, email_ids = extract_author_names_and_email_ids_from_config(config, initials)
          authors = pair_names(author_names)

          git_config = {:name => authors,  :initials => initials.sort.join(" ")}
          git_config[:email] = build_email(email_ids, config["email"]) unless no_email(config)
        else
          git_config = {:name => nil,  :initials => nil}
          git_config[:email] = nil unless no_email(config)

          puts "Unset#{' global' if global} user.name, #{'user.email, ' unless no_email(config)}user.initials"
        end

        git.config git_config.merge({:global => global})
      end

      private

      def extract_author_names_and_email_ids_from_config(config, initials) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
        authors = read_author_info_from_config(config, initials)
        authors.sort!.uniq! # FIXME
        authors.map do |a|
          full_name, email_id = a.split(";").map(&:strip)
          email_id ||= full_name.split(' ').first.downcase
          [full_name, email_id]
        end.transpose
      end

      def read_author_info_from_config(config, initials_ary) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
        initials_ary.map do |initials|
          config['pairs'][initials.downcase] or
            raise GitPairException, "Couldn't find author name for initials: #{initials}. Add this person to the .pairs file in your project or home directory."
        end
      end

      def no_email(config)
        !config.key? 'email'
      end
      
      def pair_names(author_names) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
        [author_names[0..-2].join(", "), author_names.last].reject(&:empty?).join(" and ")
      end

      def build_email(emails, config) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
        if config.is_a?(Hash)
          prefix = config['prefix'] if !config['no_solo_prefix'] or emails.size > 1
          "#{([prefix] + emails).compact.join('+')}@#{config['domain']}"
        else
          config
        end
      end
    end
  end
end

describe 'That you can choose that the author email be set to the guest'

describe 'Whether or not the settings are applied globally' do
  before do
    @git = spy("represents the current git repo")
  end
  
  it 'can be set via config' do
    config = {
      'global' => true,
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
      },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => ['bb', 'rf'], :git => @git, :config => config)

    expect(@git).to have_received(:config).with(hash_including(:global => true))
  end
  
  it 'defaults to false' do
    config_with_global_missing = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
      },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => ['bb', 'rf'], :git => @git, :config => config_with_global_missing)

    expect(@git).to have_received(:config).with(hash_including(:global => false))
  end
  
  it 'can be supplied as an option' do
    config_with_global_missing = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
      },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(
      :global => true,
      :initials => ['bb', 'rf'],
      :git => @git,
      :config => config_with_global_missing)

    expect(@git).to have_received(:config).with(hash_including(:global => true))
  end
end

describe '\`git pair\` (i.e., when you omit initials)' do
  before do
    @git = spy("represents the current git repo")

    @config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => [], :git => @git, :config => @config)
  end

  it 'sets author.{name,email} to no value' do
    expect(@git).to have_received(:config).with(hash_including(:name => nil, :email => nil))
  end
end

describe '\`git pair rb bb\`' do
  before do
    @git = spy("represents the current git repo")

    @config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => ['bb','rf'], :git => @git, :config => @config)
  end
  
  it 'sets author.name to combination of authors' do
    expect(@git).to have_received(:config).with(hash_including(:name => "Ben Biddington and Richard Bizzness"))
  end

  it 'sets author.email to a combination of email addresses' do
    expect(@git).to have_received(:config).with(hash_including(:email => "ben.biddington+ricky.bizzness@aol.com"))
  end

  it 'does not matter what order initials are supplied' do
    git = spy("represents the current git repo")
    
    UseCases::GitPair.apply(:initials => ['rf', 'bb'], :git => git, :config => @config)

    expect(git).to have_received(:config).with(hash_including(
      :name => "Ben Biddington and Richard Bizzness",
      :email => "ben.biddington+ricky.bizzness@aol.com"))
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
