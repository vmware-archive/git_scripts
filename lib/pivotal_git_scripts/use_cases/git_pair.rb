require_relative '../git_pair'

module PivotalGitScripts
  class GitPairException < Exception; end
  
  module UseCases
    module GitPair
      class << self
        def apply(opts={})
          git      = opts[:git]      || fail("You need to supply the :git config port")
          config   = opts[:config]   || fail("You need to supply :config. (The current git pair settings.)")
          initials = opts[:initials] || []
          global   = opts[:global]   || config['global'] || false

          if initials.any?
            author_names, email_ids = extract_author_names_and_email_ids_from_config(config, initials)
            authors = pair_names(author_names)

            git_config = {:name => authors, :initials => initials.sort.join(" ")}

            unless no_email(config)
              email_config = config['email']
            
              if email_config.is_a?(Hash) && email_config.key?('author')
                git_config[:email] = email_by(email_config['author'], config)
              else
                git_config[:email] = build_email(email_ids, config["email"]) 
              end
            end
          else
            git_config = {:name => nil,  :initials => nil}
            git_config[:email] = nil unless no_email(config)

            puts "Unset#{' global' if global} user.name, #{'user.email, ' unless no_email(config)}user.initials"
          end

          git.call git_config.merge({:global => global})
        end
        
        private
        
        def extract_author_names_and_email_ids_from_config(config, initials)
          authors = read_author_info_from_config(config, initials)
          authors.sort!.uniq! # FIXME

          authors.map do |a|
            full_name, email_id = name_and_email(a)
            email_id ||= full_name.split(' ').first.downcase
            [full_name, email_id]
          end.transpose
        end

        def read_author_info_from_config(config, initials_ary) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
          PivotalGitScripts::GitPair::Runner.new.read_author_info_from_config config, initials_ary
        end
        
        def no_email(config)
          !config.key? 'email'
        end
      
        def pair_names(author_names) # [!] Duplicated from lib/pivotal_git_scripts/git_pair.rb
          [author_names[0..-2].join(", "), author_names.last].reject(&:empty?).join(" and ")
        end

        def build_email(emails, config)
          if config.is_a?(Hash)          
            prefix = config['prefix'] if !config['no_solo_prefix'] or emails.size > 1
            
            "#{([prefix] + emails).compact.join('+')}@#{config['domain']}"
          else
            config
          end
        end
        
        def email_by(initials, config)
          _, email = name_and_email(config['pairs'][initials.downcase])
          "#{email}@#{config['email']['domain']}"
        end
        
        def name_and_email(text)
          text.split(";").map(&:strip)
        end
      end
    end
  end
end
