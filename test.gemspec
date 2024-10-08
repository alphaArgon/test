# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "test"
  spec.version       = "0.0"
  spec.authors       = [""]
  spec.summary       = "Jekyll test"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README|_config\.yml)!i) }

  spec.add_runtime_dependency "jekyll", "~> 3.9.0"

end
