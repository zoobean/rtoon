module Toon
  class Encoder
    def self.encode(hash, indent_level = 0)
      return "" if hash.nil? || hash.empty?

      lines = []
      indent = "  " * indent_level

      hash.each do |key, value|
        case value
        when Array
          if value.empty?
            lines << "#{indent}#{key}[0]{}:"
          elsif value.first.is_a?(Hash)
            # Array of objects - use schema format
            fields = extract_fields(value)
            lines << "#{indent}#{key}[#{value.size}]{#{fields.join(',')}}:"

            value.each do |obj|
              row_values = fields.map { |field| obj[field] || "" }
              lines << "#{indent}  #{row_values.join(',')}"
            end
          else
            # Array of primitives - treat as simple values
            lines << "#{indent}#{key}: #{value.join(',')}"
          end

        when Hash
          if value.empty?
            lines << "#{indent}#{key}{}:"
          else
            # Check if this hash contains arrays or nested hashes
            has_complex_values = value.values.any? { |v| v.is_a?(Hash) || v.is_a?(Array) }

            if has_complex_values
              # Schema block with nested content
              lines << "#{indent}#{key}[1]{}:"
              nested = encode(value, indent_level + 1)
              lines << nested unless nested.empty?
            else
              # Simple nested object
              lines << "#{indent}#{key}{}:"
              value.each do |k, v|
                lines << "#{indent}  #{k}: #{v}"
              end
            end
          end

        else
          # Simple field assignment
          lines << "#{indent}#{key}: #{value}"
        end
      end

      lines.join("\n")
    end

    private

    def self.extract_fields(array_of_hashes)
      # Get all unique keys from the array of hashes, preserving order from first object
      return [] if array_of_hashes.empty?

      first_keys = array_of_hashes.first.keys
      all_keys = array_of_hashes.flat_map(&:keys).uniq

      # Prioritize keys from first object, then add any others
      (first_keys + (all_keys - first_keys))
    end
  end
end
