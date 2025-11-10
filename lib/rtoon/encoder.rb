# lib/rtoon/encoder.rb
module Rtoon
  class Encoder
    def self.encode(value, indent: 0, key: nil, top_level: true)
      case value
      when Hash
        encode_hash(value, indent: indent, key: key, top_level: top_level)
      when Array
        encode_array(value, indent: indent, key: key, top_level: top_level)
      else
        "#{value}"
      end
    end

    def self.encode_hash(hash, indent:, key:, top_level:)
      lines = []
      if key
        subkeys = hash.keys
        lines << ("  " * indent + "#{key}{#{subkeys.join(',')}}:")
        indent += 1
      end

      hash.each do |k, v|
        if v.is_a?(Hash)
          lines << encode_hash(v, indent: indent, key: k, top_level: false)
        elsif v.is_a?(Array)
          lines << encode_array(v, indent: indent, key: k, top_level: false)
        else
          lines << ("  " * indent + "#{k}: #{v}")
        end
      end

      lines.join("\n") + (top_level ? "\n" : "")
    end

    def self.encode_array(array, indent:, key:, top_level:)
      return "" if array.empty?

      # Check if it's an array of hashes that themselves contain nested structures
      if array.first.is_a?(Hash)
        # If all elements are flat hashes (no arrays inside), compress to CSV form
        if array.all? { |h| h.values.all? { |v| !v.is_a?(Array) && !v.is_a?(Hash) } }
          element_keys = array.first.keys
          lines = []
          lines << ("  " * indent + "#{key}[#{array.size}]{#{element_keys.join(',')}}:")
          array.each do |element|
            row = element.values.join(',')
            lines << ("  " * (indent + 1) + row)
          end
          return lines.join("\n")
        else
          # Otherwise, treat each element recursively
          lines = []
          lines << ("  " * indent + "#{key}[#{array.size}]{#{array.first.keys.join(',')}}:")
          array.each do |element|
            lines << encode_hash(element, indent: indent + 1, key: nil, top_level: false)
          end
          return lines.join("\n")
        end
      else
        # Array of primitives
        lines = []
        lines << ("  " * indent + "#{key}[#{array.size}]:")
        array.each { |v| lines << ("  " * (indent + 1) + v.to_s) }
        lines.join("\n")
      end
    end
  end
end
