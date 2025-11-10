module Toon
  class Encoder
    def self.encode(hash, indent_level = 0)
      return "" if hash.nil? || hash.empty?

      result = []
      indent_str = "  " * indent_level

      hash.each do |key, value|
        if value.is_a?(Array) && value.all? { |v| v.is_a?(Hash) }
          # Array of hashes - encode as schema with rows
          fields = extract_fields(value)
          result << "#{indent_str}#{key}[#{value.length}]{#{fields.join(',')}}:"

          value.each do |row|
            row_values = fields.map { |field| format_value(row[field]) }
            result << "#{indent_str}  #{row_values.join(',')}"
          end
        elsif value.is_a?(Hash)
          # Nested hash - encode without schema (just field assignments)
          result << "#{indent_str}#{key}:"
          value.each do |nested_key, nested_value|
            result << "#{indent_str}  #{nested_key}: #{format_value(nested_value)}"
          end
        else
          # Simple key-value pair
          result << "#{indent_str}#{key}: #{format_value(value)}"
        end
      end

      result.join("\n") + "\n"
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

    def self.format_value(value)
      return "" if value.nil?
      value.to_s
    end
  end
end
