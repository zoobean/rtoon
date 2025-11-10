# frozen_string_literal: true

module Rtoon
  class Encoder
    INDENT = "  "

    def self.encode(obj, **opts)
      new(**opts).encode_document(obj)
    end

    def initialize(sort_keys: true, field_order: :sorted)
      @sort_keys = sort_keys
      @field_order = field_order
    end

    # Top-level document encoding
    def encode_document(obj, indent = 0)
      raise ArgumentError, "Document must be a Hash" unless obj.is_a?(Hash)

      output = each_key(obj, sort: true).map do |key|
        value = obj[key]
        name  = emit_ident(key)

        case value
        when Array
          if value.all? { |row| row.is_a?(Hash) }
            encode_schema_with_rows(name, value, indent)
          else
            emit_line(indent, "#{name}: #{emit_inline_list(value)}")
          end
        when Hash
          encode_nested_schema_or_fields(name, value, indent)
        else
          emit_line(indent, "#{name}: #{emit_value(value)}")
        end
      end.join("\n")

      output + "\n" # ensure final newline
    end

    private

    # ─────────────────────────────────────────────
    # Schema with data rows
    # ─────────────────────────────────────────────
    def encode_schema_with_rows(name, rows, indent)
      # Determine whether rows are simple (all scalar values) or nested
      simple_rows = rows.all? do |row|
        row.values.all? { |v| !v.is_a?(Hash) && !(v.is_a?(Array) && v.first.is_a?(Hash)) }
      end

      if simple_rows
        # Simple tabular schema → flat rows
        fields = compute_row_fields(rows)
        header = "#{name}[#{rows.length}]{#{fields.join(',')}}:"
        body = rows.map { |row| emit_line(indent + 1, emit_row(fields, row)) }.join("\n")
        "#{emit_line(indent, header)}\n#{body}"
      else
        # Nested schema case
        fields = rows.first.keys.map(&:to_s)
        header = "#{name}[#{rows.length}]{#{fields.join(',')}}:"
        lines = [emit_line(indent, header)]

        rows.each do |row|
          # Emit nested schemas first
          fields.each do |field|
            value = row[field] || row[field.to_sym]

            if value.is_a?(Hash)
              lines << encode_nested_schema_or_fields(field, value, indent + 1)
            elsif value.is_a?(Array) && value.all? { |r| r.is_a?(Hash) }
              lines << encode_schema_with_rows(field, value, indent + 1)
            end
          end

          # Emit scalar fields after nested ones
          fields.each do |field|
            value = row[field] || row[field.to_sym]
            next if value.is_a?(Hash) || (value.is_a?(Array) && value.first.is_a?(Hash))
            lines << emit_line(indent + 1, "#{emit_ident(field)}: #{emit_value(value)}")
          end
        end

        lines.join("\n")
      end
    end


    # ─────────────────────────────────────────────
    # Nested schema or mixed block
    # ─────────────────────────────────────────────
    def encode_nested_schema_or_fields(name, hash, indent)
      child_keys = each_key(hash, sort: false) # preserve insertion order

      subschema_keys = child_keys.select do |k|
        v = hash[k]
        v.is_a?(Hash) || (v.is_a?(Array) && v.first.is_a?(Hash))
      end
      field_keys = child_keys - subschema_keys

      header_fields =
        if field_keys.any?
          field_keys.map { |k| emit_ident(k) }
        elsif subschema_keys.any?
          subschema_keys.map { |k| emit_ident(k) }
        else
          ["_"]
        end

      header = "#{name}{#{header_fields.join(',')}}:"
      inner = []

      # Emit scalar fields
      field_keys.each do |k|
        v = hash[k]
        inner << emit_line(indent + 1, "#{emit_ident(k)}: #{emit_value(v)}")
      end

      # Emit nested schemas
      subschema_keys.each do |k|
        v = hash[k]
        kname = emit_ident(k)
        if v.is_a?(Hash)
          inner << encode_nested_schema_or_fields(kname, v, indent + 1)
        elsif v.is_a?(Array) && v.all? { |r| r.is_a?(Hash) }
          inner << encode_schema_with_rows(kname, v, indent + 1)
        else
          inner << emit_line(indent + 1, "#{kname}: #{emit_value(v)}")
        end
      end

      "#{emit_line(indent, header)}\n#{inner.join("\n")}"
    end

    # ─────────────────────────────────────────────
    # Helpers
    # ─────────────────────────────────────────────
    def emit_row(fields, row)
      values = fields.map { |f| emit_value(row[f.to_sym] || row[f.to_s]) }
      values.join(',')
    end

    def emit_value(v)
      case v
      when Numeric
        v.to_s
      when String
        s = v.strip
        s.match?(/\A[A-Za-z0-9_.-]+\z/) ? s : s
      when true, false
        v.to_s
      else
        v.to_s
      end
    end

    def emit_inline_list(arr)
      arr.map { |v| emit_value(v) }.join(',')
    end

    def emit_ident(s)
      s = s.to_s.strip
      return "_" if s.empty?
      identifier?(s) ? s : sanitize_identifier(s)
    end

    def sanitize_identifier(s)
      s = s.to_s.strip
      s = s.gsub(/[^A-Za-z0-9_]+/, "_").gsub(/\A[^A-Za-z_]+/, "")
      s = "_#{s}" if s.empty? || s[0] !~ /[A-Za-z_]/
      s.gsub(/_+$/, "")
    end

    def identifier?(s)
      /\A[A-Za-z_][A-Za-z0-9_]*\z/.match?(s)
    end

    def emit_line(indent, text)
      "#{INDENT * indent}#{text}"
    end

    def each_key(h, sort: false)
      sort ? h.keys.sort_by(&:to_s) : h.keys
    end

    def compute_row_fields(rows)
      union = rows.flat_map(&:keys).map(&:to_s).uniq
      case @field_order
      when :sorted then union.sort
      when :preserve then union
      else raise ArgumentError, "Unknown field_order: #{@field_order.inspect}"
      end
    end
  end
end
