# frozen_string_literal: true

require_relative "support/e2e_helper"

RSpec.describe("bundle update", :e2e) do
  # Locks every gem at 1.0.0, then loosens the requirements so there is something to update
  before do
    write_gemfiles("1.0.0")
    project.bundle!("install")
    write_gemfiles(">= 1.0")
  end

  def write_gemfiles(requirement)
    project.gemfile("Gemfile", %(gem "harry", "#{requirement}"\n))
    project.gemfile("ci.gemfile", %(gem "harry", "#{requirement}"\ngem "hermoine", "#{requirement}"\n))
    project.gemfile("gemfiles/rails.gemfile", %(gem "ron", "#{requirement}"\n))
  end

  it "updates a named gem in every lockfile that has it, and skips the rest", :aggregate_failures do
    output = project.bundle!("update", "harry").output

    expect(output).to include("gemfiles/rails.gemfile: skipped, none of harry are in this gemfile")
    expect(project.locked("Gemfile")).to include("harry" => "2.0.0")
    expect(project.locked("ci.gemfile")).to eq("harry" => "2.0.0", "hermoine" => "1.0.0")
    expect(project.locked("gemfiles/rails.gemfile")).to eq("ron" => "1.0.0")
  end

  it "updates every gem in every gemfile with --all", :aggregate_failures do
    project.bundle!("update", "--all")

    expect(project.locked("ci.gemfile")).to eq("harry" => "2.0.0", "hermoine" => "1.1.0")
    expect(project.locked("gemfiles/rails.gemfile")).to eq("harry" => "2.0.0", "ron" => "1.2.0")
  end

  # A gemfile's own .bundle/config wins over the project's, so only this gemfile is frozen
  # rubocop:disable-next RSpec/ExampleLength
  it "updates the other gemfiles when a secondary gemfile fails, then fails naming it", :aggregate_failures do
    project.gemfile("engines/admin/Gemfile", %(gem "harry", "1.0.0"\n))
    project.config("matrix.paths", "engines/*")
    project.bundle!("install")
    project.gemfile("engines/admin/Gemfile", %(gem "harry"\n))
    project.config("frozen", true, dir: "engines/admin")

    result = project.bundle("update", "--all")

    expect(result).not_to be_success
    expect(result.stderr).to include("bundle_matrix: failed for engines/admin/Gemfile")
    expect(project.locked("Gemfile")).to include("harry" => "2.0.0")
    expect(project.locked("gemfiles/rails.gemfile")).to include("ron" => "1.2.0")
  end

  it "does nothing when the main update fails", :aggregate_failures do
    before = project.read("ci.gemfile.lock")

    result = project.bundle("update", "nonexistent")

    expect(result).not_to be_success
    expect(result.output).not_to include("== bundle_matrix")
    expect(project.read("ci.gemfile.lock")).to eq(before)
  end
end
