require 'spec_helper'
require 'pivotal_git_scripts/author'

describe Author do
  describe '.build_from_initials(initials, config)' do
    let(:config) {
      {
        'pairs' => {
          'aa' => 'Anna Arrent; aarrent',
          'bb' => 'Bob Bilgewater; bbilgewater'
        },
        'email' => {
          'domain' => 'example.com'
        }
      }
    }

    it 'returns an entry for each author' do
      Author.build_from_initials(%w(aa bb), config).should have(2).entries
    end

    it 'sets the author names properly' do
      authors = Author.build_from_initials(%w(aa bb), config)
      authors.map(&:full_name).should =~ ['Anna Arrent', 'Bob Bilgewater']
    end

    it 'sets the author email properly' do
      authors = Author.build_from_initials(%w(aa bb), config)
      authors.map(&:email_address).should =~ %w(aarrent@example.com bbilgewater@example.com)
    end

    context 'when duplicate initials are given' do
      it 'ignores the duplicate'
    end

    context 'when no email_id is given' do
      it "sets the email_id to the author's first name"
    end

    context 'when some initials have no matching author' do
      it 'raises an exception' # see read_author_info_from_config
    end
  end
end
