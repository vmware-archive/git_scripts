class MockGitConfig
  include RSpec::Matchers
  
  def fun
    ->(*args) do
      @args = args
    end
  end

  def must_have_received(expected={})
    expect(@args).to include(expected)
  end
end
