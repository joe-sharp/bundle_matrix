# frozen_string_literal: true

require_relative "support/e2e_helper"

RSpec.describe("bundle install with a gems.rb main file", :e2e) do
  before do
    project.config("matrix.default_gemfile", "gems.rb")
    project.gemfile("gems.rb", %(gem "harry", "~> 1.0.0"\n))
    project.gemfile("ci.gemfile", %(gem "harry", "~> 1.0"\ngem "hermoine", "1.0.0"\n))
    project.gemfile("engines/web/gems.rb", %(gem "ron", "1.0.0"\n))
    project.config("matrix.paths", "engines/*")
  end

  it "fans out from gems.rb and locks each file in its own lockfile", :aggregate_failures do
    output = project.bundle!("install").output

    expect(output).to include(header("ci.gemfile", "install"), header("engines/web/gems.rb", "install"))
    expect(project).to exist("gems.locked")
    expect(project.read("ci.gemfile.lock")).to include("hermoine")
    expect(project.read("engines/web/gems.locked")).to include("ron")
  end
end
