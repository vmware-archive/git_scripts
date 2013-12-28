class Author
  def self.build_from_initials(initials, config)
    initials.map { |letters|
      config_line = config.fetch('pairs').fetch(letters)
      full_name, email_id = config_line.split(';').map(&:strip)
      new(
        full_name: full_name,
        email_id: email_id,
        email_domain: config.fetch('email').fetch('domain')
      )
    }
  end

  attr_reader :full_name, :email_id, :email_domain

  def initialize(attrs)
    @full_name = attrs.fetch(:full_name)
    @email_id = attrs.fetch(:email_id)
    @email_domain = attrs.fetch(:email_domain)
  end

  def email_address
    "#{email_id}@#{email_domain}"
  end
end
