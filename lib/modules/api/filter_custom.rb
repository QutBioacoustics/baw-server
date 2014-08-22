require 'active_support/concern'

module Api

  # Provides comparisons for composing queries.
  module FilterCustom
    extend ActiveSupport::Concern
    extend FilterComparison
    extend FilterCore
    extend FilterSubset
    extend Validate

    private

    # Build project creator condition.
    # @param [Integer] creator_id
    # @return [Arel::Nodes::Node] condition
    def build_project_creator(creator_id)
      # creator_id_check = 'projects.creator_id = ?'
      compose_eq(relation_table(Project), :creator_id, [:creator_id], creator_id)
    end

    # Build user permissions condition.
    # @param [Integer] user_id
    # @return [Arel::Nodes::Node] condition
    def build_user_permissions(user_id)
      # permissions_check = 'permissions.user_id = ? AND permissions.level IN (\'reader\', \'writer\')'
      user_permissions = compose_eq(relation_table(Permission), :user_id, [:user_id], user_id)
      permission_level = compose_in(relation_table(Permission), :level, [:level], %w(reader writer))
      compose_and(user_permissions, permission_level)
    end

    # Build project creator condition.
    # @param [Boolean] is_reference
    # @return [Arel::Nodes::Node] condition
    def build_audio_event_reference(is_reference)
      # reference_audio_event_check = 'audio_events.is_reference IS TRUE'
      compose_eq(relation_table(AudioEvent), :is_reference, [:is_reference], is_reference)
    end

    # Build permission check condition.
    # @param [Integer] user_id
    # @param [Boolean] is_reference
    # @return [Arel::Nodes::Node] condition
    def build_permission_check(user_id, is_reference)
      # where("((#{creator_id_check}) OR (#{permissions_check}) OR (#{reference_audio_event_check}))", user.id, user.id)
      compose_or(
          compose_or(
              build_project_creator(user_id),
              build_user_permissions(user_id)
          ),
          build_audio_event_reference(is_reference)
      )
    end

    # Create SIMILAR TO condition for text.
    # @param [Arel::Table] table
    # @param [Symbol] column_name
    # @param [Array<Symbol>] text_allowed
    # @param [Array<String>] text_array
    # @return [Arel::Nodes::Node] condition
    def compose_similar(table, column_name, text_allowed, text_array)

      #tags_partial = CSV.parse(params[:tagsPartial], col_sep: ',').flatten.map { |item| item.trim(' ', '') }.join('|').downcase
      #tags_query = AudioEvent.joins(:tags).where('lower(tags.text) SIMILAR TO ?', "%(#{tags_partial})%").select('audio_events.id')

      validate_table_column(table, column_name, text_allowed)
      sanitized_value = text_array.map { |item| sanitize_similar_to_value(item.trim(' ', '')) }.join('|').downcase
      contains_value = "%(#{sanitized_value})%"
      lower_value = "lower(#{table.name}.#{column_name})"
      similar = "#{lower_value} SIMILAR TO #{contains_value}"

      Arel::Nodes::SqlLiteral.new(similar)
    end

  end
end

#Arel::Nodes::SqlLiteral

# Arel::Nodes::SqlLiteral.new(<<-SQL
#     CASE WHEN condition1 THEN calculation1
#     WHEN condition2 THEN calculation2
#     WHEN condition3 THEN calculation3
#     ELSE default_calculation END
# SQL
# )