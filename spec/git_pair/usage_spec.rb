require 'pivotal_git_scripts/use_cases/git_pair'
require 'support'

describe 'Whether or not the settings are applied globally' do
  before do
    @git = MockGitConfig.new
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
    
    UseCases::GitPair.apply(:initials => ['bb', 'rf'], :git => @git.fun, :config => config)

    @git.must_have_received(hash_including(:global => true))
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
    
    UseCases::GitPair.apply(:initials => ['bb', 'rf'], :git => @git.fun, :config => config_with_global_missing)

    @git.must_have_received(hash_including(:global => false))
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
      :git => @git.fun,
      :config => config_with_global_missing)

    @git.must_have_received(hash_including(:global => true))
  end
end

describe '\`git pair\` (i.e., when you omit initials)' do
  before do
    @git = MockGitConfig.new
    
    @config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => [], :git => @git.fun, :config => @config)
  end

  it 'sets author.{name,email} to no value' do
    @git.must_have_received(hash_including(:name => nil, :email => nil))
  end
end

describe '\`git pair rb bb\`' do
  before do
    @git = MockGitConfig.new

    @config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {
        'domain' => 'aol.com',
        'no_solo_prefix' => true}
    }
    
    UseCases::GitPair.apply(:initials => ['bb','rf'], :git => @git.fun, :config => @config)
  end
  
  it 'sets author.name to combination of authors' do
    @git.must_have_received(hash_including(:name => "Ben Biddington and Richard Bizzness"))
  end

  it 'sets author.email to a combination of email addresses' do
    @git.must_have_received(hash_including(:email => "ben.biddington+ricky.bizzness@aol.com"))
  end

  it 'does not matter what order initials are supplied' do
    UseCases::GitPair.apply(:initials => ['rf', 'bb'], :git => @git.fun, :config => @config)

    @git.must_have_received(hash_including(
      :name => "Ben Biddington and Richard Bizzness",
      :email => "ben.biddington+ricky.bizzness@aol.com"))
  end
  
  describe 'that you may configure it such that \`git pair\` sets auther email, too'
end
