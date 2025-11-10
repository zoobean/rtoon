require_relative 'toon/parser.tab'
require_relative 'toon/encoder'

module Toon
  VERSION = "0.1.0"

  def self.parse(string)
    parser = Parser.new
    parser.parse(string)
  end

  def self.decode(string)
    parse(string)
  end

  def self.encode(hash, indent_level = 0)
    Encoder.encode(hash, indent_level)
  end
end
