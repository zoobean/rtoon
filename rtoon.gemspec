Gem::Specification.new do |spec|
  spec.name          = "rtoon"
  spec.version       = "0.1.0"
  spec.authors       = ["Antonio Chavez"]
  spec.email         = ["antonio@zoobean.com"]

  spec.summary       = "Parser for Token Object Oriented Notation (TOON)"
  spec.description   = "A Ruby library for parsing TOON, a tabular, schema-based data format with indentation-based structure"
  spec.homepage      = "https://github.com/zoobean/rtoon"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md", "TOON_SPEC.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "racc", "~> 1.7"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
