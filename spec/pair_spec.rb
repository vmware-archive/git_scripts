require 'spec_helper'
require 'pivotal_git_scripts/pair'
require 'pivotal_git_scripts/author'

describe Pair do
  describe '.build_with_random_credited_author' do
    let(:author_a) { Author.new(full_name: 'Anne Atkinson', email_id: 'anne', email_domain: 'example.com') }
    let(:author_b) { Author.new(full_name: 'Bob Bilgewater', email_id: 'bob', email_domain: 'example.com') }

    it 'sets the email_address to that of a randomly chosen author' do
      email_addresses = 6.times.map do
        Pair.build_with_random_credited_author([author_a, author_b]).email_address
      end.uniq

      email_addresses.should =~ [author_a.email_address, author_b.email_address]
    end

    it 'sets the compound_name to include all author names, with the credited author first' do
      compound_name_for_email = 6.times.with_object({}) do |_, hash|
        pair = Pair.build_with_random_credited_author([author_a, author_b])
        hash[pair.email_address] = pair.compound_name
      end

      compound_name_for_email.should == {
        'anne@example.com' => 'Anne Atkinson and Bob Bilgewater',
        'bob@example.com' => 'Bob Bilgewater and Anne Atkinson',
      }
    end

    context 'when the "pair" has more than 2 members' do
      it 'constructs a compound name with commas and a final "and"'
    end
  end
end
