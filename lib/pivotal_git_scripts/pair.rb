class Pair
  def self.build_with_random_credited_author(authors)
    credited_author = authors.sample
    ordered_authors = [credited_author, *authors.reject {|a| a == credited_author}]
    new(
      authors: ordered_authors,
      email_address: credited_author.email_address,
    )
  end

  attr_reader :email_address, :authors

  def initialize(attrs)
    @email_address = attrs.fetch(:email_address)
    @authors = attrs.fetch(:authors)
  end

  def compound_name
    authors.map(&:full_name).join(' and ')
  end
end
