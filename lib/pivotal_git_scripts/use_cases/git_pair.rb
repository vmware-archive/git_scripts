module UseCases
  class GitPair
    class << self
      def apply(opts={})
        git      = opts[:git]      || fail("You need to supply the :git config port")
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

        git.call git_config.merge({:global => global})
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
