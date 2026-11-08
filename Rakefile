# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) { |t| t.exclude_pattern = "spec/e2e/**/*_spec.rb" }

desc "Run the end-to-end specs, which run real bundle commands"
RSpec::Core::RakeTask.new(:e2e) { |t| t.pattern = "spec/e2e/**/*_spec.rb" }

RuboCop::RakeTask.new

desc "Validate the RBS signatures in sig/, with stubs for the Bundler types they name"
task :rbs do
  sh "rbs", "-I", "sig", "-I", "sig_stubs", "validate"
end

desc "Type check lib/ against the signatures in sig/ with Steep"
task :steep do
  sh "steep", "check"
end

# Replaces Bundler's release task.
Rake::Task["release"].clear
desc "Tag, push, build and publish the gemspec version, asking for a description if not given"
task(:release, [:description]) { |_, args| exec "bin/release", *[args.to_a.join(", ")].reject(&:empty?) }

task default: %i[spec e2e rubocop rbs steep]
