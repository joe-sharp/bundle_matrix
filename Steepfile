# frozen_string_literal: true

D = Steep::Diagnostic

# Type checks lib/ against sig/. Bundler publishes no signatures, so sig_stubs/ declares the parts of its API we call.
target :lib do
  signature "sig", "sig_stubs"
  check "lib"

  library "pathname"

  # Annotating every empty [] and {} adds noise; the method signatures still check what they end up holding
  configure_code_diagnostics(D::Ruby.default) do |hash|
    hash[D::Ruby::UnannotatedEmptyCollection] = nil
  end
end
