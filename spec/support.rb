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

  def must_not_have_received(expected={})
    expect(@args).to_not include(expected)
  end
end
