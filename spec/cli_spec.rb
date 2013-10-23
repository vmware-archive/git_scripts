require "unindent"
require 'open3'

describe "CLI" do
  before :all do
    # use local scripts
    ENV["PATH"] = "#{File.join(File.dirname(__FILE__),"..","bin")}:#{ENV["PATH"]}"
  end

  def run(cmd, options={})
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      output = stdout_and_stderr.read
      return output if wait_thr.value.success?
      return output if options[:fail]

      message = "Unable to run #{cmd.inspect} in #{Dir.pwd}.\n#{output}"
      warn "ERROR: #{message}"
      raise message unless options[:fail]
    end
  end

  def write(file, content)
    File.open(file, 'w'){|f| f.write content }
  end

  around do |example|
    dir = "spec/tmp"
    run "rm -rf #{dir}"
    run "mkdir #{dir}"

    # use fake home for .ssh hacks
    run "mkdir #{dir}/home"
    ENV["HOME"] = File.expand_path("#{dir}/home")

    Dir.chdir dir do
      run "touch a"
      run "git init"
      run "git add ."
      run "git config user.email 'rspec-tests@example.com'"
      run "git config user.name 'rspec test suite'"
      run "git commit -am 'initial'"
      run "git config --unset user.email"
      run "git config --unset user.name"
      example.run
    end
  end

  describe "about" do
    it "lists the user" do
      run "git config user.name NAME"
      run("git about").should =~ /git user:\s+NAME/
    end

    it "lists the user as NONE if there is none" do
      run "git config user.name ''"
      run("git about").should =~ /git user:\s+NONE/
    end

    it "lists the email" do
      run "git config user.email EMAIL"
      run("git about").should =~ /git email:\s+EMAIL/
    end

    it "lists the email as NONE if there is none" do
      run "git config user.email ''"
      run("git about").should =~ /git email:\s+NONE/
    end

    it "does not find a project" do
      run("git about").should =~ /GitHub project:\s+NONE/
    end

    context "with github project" do
      before do
        run "mkdir home/.ssh"
        run "touch home/.ssh/id_github_foo"
        run "ln -s home/.ssh/id_github_foo home/.ssh/id_github_current"
      end

      it "finds a project" do
        run("git about").should =~ /GitHub project:\s+foo/
      end
    end
  end

  describe "pair" do
    def expect_config(result, name, initials, email, options={})
      global = "cd /tmp && " if options[:global]
      run("#{global}git config user.name").should == "#{name}\n"
      run("#{global}git config user.initials").should == "#{initials}\n"
      run("#{global}git config user.email").should == "#{email}\n"

      prefix = (options[:global] ? "global: " : "local:  ")
      result.should include "#{prefix}user.name #{name}"
      result.should include "#{prefix}user.initials #{initials}"
      result.should include "#{prefix}user.email #{email}"
    end

    def git_config_value(name, global = false)
      global_prefix = "cd /tmp && " if global
      `#{global_prefix}git config user.#{name}`
    end

    it "prints help" do
      result = run "git-pair --help"
      result.should include("Configures git authors when pair programming")
    end

    it "prints version" do
      result = run "git pair --version"
      result.should =~ /\d+\.\d+\.\d+/
    end

    context "with .pairs file" do
      before do
        write ".pairs", <<-YAML.unindent
          pairs:
            ab: Aa Bb
            bc: Bb Cc
            cd: Cc Dd

          email:
            prefix: the-pair
            domain: the-host.com
          YAML
      end

      describe "global" do
        it "sets pairs globally when global: true is set" do
          write ".pairs", File.read(".pairs") + "\nglobal: true"
          result = run "git pair ab"
          expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com", :global => true
        end

        it "sets pairs globally when --global is given" do
          result = run "git pair ab --global"
          result.should include "global: user.name Aa Bb"
          expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com", :global => true
        end

        it "unsets global config when no argument is passed" do
          run "git pair ab --global"
          run "git pair ab"
          result = run "git pair --global"
          #result.should include "Unset --global user.name, user.email and user.initials"
          expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com"
          result.should_not include("global:")
        end
      end

      it "can set a single user as pair" do
        result = run "git pair ab"
        expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com"
      end

      it "can set a 2 users as pair" do
        result = run "git pair ab bc"
        expect_config result, "Aa Bb and Bb Cc", "ab bc", "the-pair+aa+bb@the-host.com"
      end

      it "can set n users as pair" do
        result = run "git pair ab bc cd"
        expect_config result, "Aa Bb, Bb Cc and Cc Dd", "ab bc cd", "the-pair+aa+bb+cc@the-host.com"
      end

      it "prints names, email addresses, and initials in alphabetical order" do
        result = run "git pair ab cd bc"
        expect_config result, "Aa Bb, Bb Cc and Cc Dd", "ab bc cd", "the-pair+aa+bb+cc@the-host.com"
      end

      it "can set a user with apostrophes as pair" do
        write ".pairs", File.read(".pairs").sub("Aa Bb", "Pete O'Connor")
        result = run "git pair ab"
        expect_config result, "Pete O'Connor", "ab", "the-pair+pete@the-host.com"
      end

      it "fails when there is no .git in the tree" do
        run "rm -f /tmp/pairs"
        run "cp .pairs /tmp"
        Dir.chdir "/tmp" do
          result = run "git pair ab 2>&1", :fail => true
          result.should include("Not a git repository (or any of the parent directories)")
        end
        run "rm -f /tmp/pairs"
      end

      it "finds .pairs file in lower parent folder" do
        run "mkdir foo"
        Dir.chdir "foo" do
          result = run "git pair ab"
          expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com"
        end
      end

      it "unsets local config when no argument is passed" do
        run "git pair ab --global"
        run "git pair bc"
        result = run "git pair"
        result.should include "Unset user.name, user.email, user.initials"
        expect_config result, "Aa Bb", "ab", "the-pair+aa@the-host.com", :global => true
        result.should_not include("local:")
      end

      it "uses hard email when given" do
        write ".pairs", File.read(".pairs").sub(/email:.*/m, "email: foo@bar.com")
        result = run "git pair ab"
        expect_config result, "Aa Bb", "ab", "foo@bar.com"
      end

      context "when no email config is present" do
        before do
          write ".pairs", File.read(".pairs").sub(/email:.*/m, "")
        end

        it "doesn't set email" do
          run "git pair ab"
          git_config_value('email').should be_empty
        end

        it "doesn't report about email" do
          result = run "git pair ab"
          result.should_not include "email"
        end
      end

      it "uses no email prefix when only host is given" do
        write ".pairs", File.read(".pairs").sub(/email:.*/m, "email:\n  domain: foo.com")
        result = run "git pair ab"
        expect_config result, "Aa Bb", "ab", "aa@foo.com"
      end

      context "when no no_solo_prefix is given" do
        before do
          write ".pairs", File.read(".pairs").sub(/email:.*/m, "email:\n  prefix: pairs\n  no_solo_prefix: true\n  domain: foo.com")
        end

        it "uses no email prefix for single developers" do
          result = run "git pair ab"
          expect_config result, "Aa Bb", "ab", "aa@foo.com"
        end

        it "uses email prefix for multiple developers" do
          result = run "git pair ab bc"
          expect_config result, "Aa Bb and Bb Cc", "ab bc", "pairs+aa+bb@foo.com"
        end
      end

      it "fails with unknown initials" do
        result = run "git pair xx", :fail => true
        result.should include("Couldn't find author name for initials: xx")
      end

      it "uses alternate email prefix" do
        write ".pairs", File.read(".pairs").sub(/ab:.*/, "ab: Aa Bb; blob")
        result = run "git pair ab"
        expect_config result, "Aa Bb", "ab", "the-pair+blob@the-host.com"
      end
    end

    context "without a .pairs file in the tree" do
      around do |example|
        Dir.chdir "/tmp" do
          run "rm -f .pairs"
          dir = "git_stats_test"
          run "rm -rf #{dir}"
          run "mkdir #{dir}"
          Dir.chdir dir do
            run "git init"
            example.run
          end
          run "rm -rf #{dir}"
        end
      end

      it "fails if it cannot find a pairs file" do
        run "git pair ab", :fail => true
      end

      it "prints instructions" do
        result = run "git pair ab", :fail => true
        result.should include("Could not find a .pairs file. Create a YAML file in your project or home directory.")
      end
    end
  end
end
