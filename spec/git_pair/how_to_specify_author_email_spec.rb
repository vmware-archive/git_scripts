require 'pivotal_git_scripts/use_cases/git_pair'
require 'support'

include PivotalGitScripts

describe 'How to specify what value to use for user.email' do
  before do
    @git = MockGitConfig.new
  end

  it 'sets author.email to the email address for whomever you specify as the author in the email settings' do
    config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {
        'author' => 'rf',
        'domain' => 'aol.com'}
    }
    
    UseCases::GitPair.apply(:initials => ['bb','rf'], :git => @git.fun, :config => config)
    
    @git.must_have_received(hash_including(:email => "ricky.bizzness@aol.com"))
  end

  it 'does what when email author alias is not present in pairs?'
  
  it 'sets author.email to a combination of email addresses by default' do
    config = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        },
      'email' => {'domain' => 'aol.com'}
    }
    
    UseCases::GitPair.apply(:initials => ['bb','rf'], :git => @git.fun, :config => config)
    
    @git.must_have_received(hash_including(:email => "ben.biddington+ricky.bizzness@aol.com"))
  end

  it 'does not set author.email at all when no email setting is present in config' do
    config_with_missing_email_setting = {
      'pairs' => {
        'bb' => "Ben Biddington; ben.biddington",
        'rf' => "Richard Bizzness; ricky.bizzness",
        }
    }
    
    UseCases::GitPair.apply(:initials => ['bb','rf'], :git => @git.fun, :config => config_with_missing_email_setting)
    
    @git.must_not_have_received(:email)
  end
end
