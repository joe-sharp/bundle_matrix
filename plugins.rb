# frozen_string_literal: true

require_relative "lib/bundle_matrix"

Bundler::Plugin::API.hook(Bundler::Plugin::Events::GEM_AFTER_INSTALL_ALL) do |_dependencies|
  BundleMatrix::Hook.call
end
