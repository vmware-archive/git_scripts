require "pivotal_git_scripts/version"
require 'yaml'
require 'optparse'
require 'pathname'

module PivotalGitScripts
  module GitPair
    def self.main(argv)
      runner = Runner.new
      runner.main(argv)
    end

    def self.commit(argv)
      runner = Runner.new
      runner.commit(argv)
    end

    class GitPairException < Exception; end

    class Runner
      def main(argv)
        git_dir = `git rev-parse --git-dir`.chomp
        exit 1 if git_dir.empty?

        options = parse_cli_options(argv)
        initials = argv
        config = read_pairs_config
        global = !!(options[:global] || config["global"])

        if initials.any?
          author_names, email_ids = extract_author_names_and_email_ids_from_config(config, initials)
          authors = pair_names(author_names)
          git_config = {:name => authors,  :initials => initials.sort.join(" ")}
          git_config[:email] = build_email(email_ids, config["email"]) unless no_email(config)
          set_git_config global,  git_config
        else
          git_config = {:name => nil,  :initials => nil}
          git_config[:email] = nil unless no_email(config)
          set_git_config global, git_config
          puts "Unset#{' global' if global} user.name, #{'user.email, ' unless no_email(config)}user.initials"
        end

        [:name, :email, :initials].each do |key|
          report_git_settings(git_dir, key)
        end
      rescue GitPairException => e
        puts e.message
        exit 1
      end

      def commit(argv)
        if argv[0] == '-h'
          puts 'Usage: git pair-commit [options_for_git_commit]'
          puts ''
          puts 'Commits changes to the repository using `git commit`, but randomly chooses the author email from the'
          puts 'members of the pair. In order for GitHub to assign credit for the commit activity, the user\'s email'
          puts 'must be linked in their GitHub account.'
          exit 0
        end

        config = read_pairs_config
        author_details = extract_author_details_from_config(config, current_pair_initials)
        author_names = author_details.keys.map { |i| author_details[i][:name] }
        authors = pair_names(author_names)
        author_email = random_author_email(author_details)
        puts "Committing under #{author_email}"
        passthrough_args =  argv.map{|arg| %Q{"#{arg}"}}.join(' ')
        system %Q{git -c user.name="#{authors}" -c user.email="#{author_email}" commit #{passthrough_args}}
      rescue GitPairException => e
        puts e.message
        exit 1
      end

      def current_pair_initials
        initials = `git config user.initials`.strip.split(' ')
        raise GitPairException, 'Error: No pair set. Please set your pair with `git pair ...`' if initials.empty?
        initials
      end

      def parse_cli_options(argv)
        options = {}
        OptionParser.new do |opts|
          # copy-paste from readme
          opts.banner = <<BANNER.sub('<br/>','')
      Configures git authors when pair programming.

          git pair sp js
          user.name=Josh Susser and Sam Pierson
          user.email=pair+jsusser+sam@pivotallabs.com


      Create a `.pairs` config file in project root or your home folder.

          # .pairs - configuration for 'git pair'
          pairs:
            # <initials>: <Firstname> <Lastname>[; <email-id>]
            eh: Edward Hieatt
            js: Josh Susser; jsusser
            sf: Serguei Filimonov; serguei
          # if email section is present, email will be set
          # if you leave out the email config section, email will not be set
          email:
            prefix: pair
            domain: pivotallabs.com
            # no_solo_prefix: true
          #global: true
          # include the following section to set custom email addresses for users
          #email_addresses:
          #  zr: zach.robinson@example.com


      By default this affects the current project (.git/config).<br/>
      Use the `--global` option or add `global: true` to your `.pairs` file to set the global git configuration for all projects (~/.gitconfig).

      Options are:
BANNER
          opts.on("-g", "--global", "Modify global git options instead of local") { options[:global] = true }
          opts.on("-v", "--version", "Show Version") do
            puts PivotalGitScripts::VERSION
            exit
          end
          opts.on("-h", "--help", "Show this.") { puts opts; exit }
        end.parse!(argv)

        options
      end

      def read_pairs_config
        pairs_file_name = '.pairs'

        directory = File.absolute_path(Dir.pwd)
        candidate_directories = [directory]
        while ! Pathname.new(directory).root? do
          directory = File.absolute_path(File.join(directory, ".."))
          candidate_directories << directory
        end
        home = File.absolute_path(ENV["HOME"])
        candidate_directories << home unless candidate_directories.include? home

        pairs_file_path = candidate_directories.
          map { |d| File.join(d, ".pairs") }.
          find { |f| File.exists? f }

        unless pairs_file_path
          raise GitPairException, <<-INSTRUCTIONS
      Could not find a .pairs file. Create a YAML file in your project or home directory.
      Format: <initials>: <name>[; <email>]
      Example:
      # .pairs - configuration for 'git pair'
      # place in project or home directory
      pairs:
        eh: Edward Hieatt
        js: Josh Susser; jsusser
        sf: Serguei Filimonov; serguei
      email:
        prefix: pair
        domain: pivotallabs.com
      INSTRUCTIONS
        end

        YAML.load_file(pairs_file_path)
      end

      def read_author_info_from_config(config, initials_ary)
        initials_ary.map do |initials|
          config['pairs'][initials.downcase] or
            raise GitPairException, "Couldn't find author name for initials: #{initials}. Add this person to the .pairs file in your project or home directory."
        end
      end

      def build_email(emails, config)
        if config.is_a?(Hash)
          prefix = config['prefix'] if !config['no_solo_prefix'] or emails.size > 1
          "#{([prefix] + emails).compact.join('+')}@#{config['domain']}"
        else
          config
        end
      end

      def random_author_email(author_details)
        author_id = author_details.keys.sample
        author_details[author_id][:email]
      end

      def set_git_config(global, options)
        options.each do |key,value|
          config_key = "user.#{key}"
          arg = value ? %Q{#{config_key} "#{value}"} : "--unset #{config_key}"
          system(%Q{git config#{' --global' if global} #{arg}})
        end
      end

      def report_git_settings(git_dir, key)
        global = `git config --global --get-regexp "^user\.#{key}"`
        local = `git config -f #{git_dir}/config --get-regexp "^user\.#{key}"`
        if global.length > 0 && local.length > 0
          puts "NOTE: Overriding global user.#{key} setting with local."
        end
        puts "global: #{global}" if global.length > 0
        puts "local:  #{local}" if local.length > 0
      end

      def extract_author_names_and_email_ids_from_config(config, initials)
        authors = read_author_info_from_config(config, initials)
        authors.sort!.uniq! # FIXME
        authors.map do |a|
          full_name, email_id = a.split(";").map(&:strip)
          email_id ||= full_name.split(' ').first.downcase
          [full_name, email_id]
        end.transpose
      end

      def no_email(config)
        !config.key? 'email'
      end

      def extract_author_details_from_config(config, initials)
        details = {}

        initials.each do |i|
          info = read_author_info_from_config(config, [i]).first

          full_name, email_id = info.split(";").map(&:strip)
          email_id ||= full_name.split(' ').first.downcase

          email = read_custom_email_address_from_config(config, i)
          email ||= "#{email_id}@#{config['email']['domain']}"

          details[i] = {
            :name => full_name,
            :email => email
          }
        end

        details
      end

      def read_custom_email_address_from_config(config, initial)
        return nil unless config['email_addresses']
        return config['email_addresses'][initial.downcase]
      end

      private

      def pair_names(author_names)
        [author_names[0..-2].join(", "), author_names.last].reject(&:empty?).join(" and ")
      end
    end
  end
end
