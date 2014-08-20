# Provides subset filtering (contains, in, range) for composing queries.
module ModelFilter
  class Subset
    include Validate

    class << self
      public

      # Create contains condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_contains(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        sanitized_value = sanitize_like_value(value)
        contains_value = "%#{sanitized_value}%"
        table[column_name].matches(contains_value)
      end

      # Create starts_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_starts_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        sanitized_value = sanitize_like_value(value)
        contains_value = "#{sanitized_value}%"
        table[column_name].matches(contains_value)
      end

      # Create ends_with condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_ends_with(table, column_name, allowed, value)
        validate_table_column(table, column_name, allowed)
        sanitized_value = sanitize_like_value(value)
        contains_value = "%#{sanitized_value}"
        table[column_name].matches(contains_value)
      end

      # Create IN condition.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Array] values
      # @return [Arel::Nodes::Node] condition
      def compose_in(table, column_name, allowed, values)
        fail ArgumentError, "values must be an Array, got #{values.inspect}" unless values.is_a?(Array)
        validate_table_column(table, column_name, allowed)
        table[column_name].in(values)
      end

      # Create IN condition using range.
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [String] range_string
      # @return [Arel::Nodes::Node] condition
      def compose_range_string(table, column_name, allowed, range_string)
        validate_table_column(table, column_name, allowed)

        # cannot represent exclusive lower bound
        range_regex = /\[(.*),(.*)(\)|\])/i
        matches = range_string.match(range_regex)
        fail ArgumentError, "Range string must be in the form [.*,.*]|), got #{range_string.inspect}" unless matches

        captures = matches.captures
        exclude_end = captures[2] == ')'
        range = Range.new(captures[0], captures[1], exclude_end)

        table[column_name].in(range)
      end

      # Create IN condition using from (inclusive) and to (exclusive).
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] from
      # @param [Object] to
      # @return [Arel::Nodes::Node] condition
      def compose_range(table, column_name, allowed, from, to)
        validate_table_column(table, column_name, allowed)
        range = Range.new(from, to, true)
        table[column_name].in(range)
      end

      # Create regular expression condition.
      # Available in Arel 6?
      # @param [Arel::Table] table
      # @param [Symbol] column_name
      # @param [Array<Symbol>] allowed
      # @param [Object] value
      # @return [Arel::Nodes::Node] condition
      def compose_regex(table, column_name, allowed, value)
        fail NotImplementedError
        validate_table_column(table, column_name, allowed)
        table[column_name] =~ value
      end

    end
  end
end