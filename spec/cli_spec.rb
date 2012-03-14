describe "CLI" do
  before :all do
    # use local scripts
    ENV["PATH"] = "#{File.join(File.dirname(__FILE__),"..","bin")}:#{ENV["PATH"]}"
  end

  def run(command)
    result = `#{command}`
    raise "FAILED #{command} : #{result}" unless $?.success?
    result
  end

  around do |example|
    dir = "spec/tmp"
    run "rm -rf #{dir}"
    run "mkdir #{dir}"

    # use fake home for .ssh hacks
    run "mkdir #{dir}/home"
    ENV["HOME"] = File.expand_path("#{dir}/home")

    Dir.chdir dir do
      run "touch a && git init && git add . && git commit -am 'initial'"
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
end
