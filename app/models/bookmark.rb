# frozen_string_literal: true

class Bookmark < ApplicationRecord
  # ensures that creator_id, updater_id, deleter_id are set
  include UserChange

  # relations
  belongs_to :audio_recording, inverse_of: :bookmarks

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id, inverse_of: :created_bookmarks
  belongs_to :updater, class_name: 'User', foreign_key: :updater_id, inverse_of: :updated_bookmarks, optional: true

  # association validations
  validates_associated :audio_recording
  validates_associated :creator

  # attribute validations
  validates :offset_seconds, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :audio_recording_id, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :creator_id, message: 'should be unique per user' }

  # Define filter api settings
  def self.filter_settings
    {
      valid_fields: [:id, :audio_recording_id, :name, :category, :description, :offset_seconds, :created_at, :creator_id, :updater_id, :updated_at],
      render_fields: [:id, :audio_recording_id, :name, :category, :description, :offset_seconds, :created_at, :creator_id, :updater_id, :updated_at],
      text_fields: [:name, :description, :category],
      custom_fields: lambda { |item, _user|
        [item, item.render_markdown_for_api_for(:description)]
      },
      controller: :bookmarks,
      action: :filter,
      defaults: {
        order_by: :created_at,
        direction: :desc
      },
      valid_associations: [
        {
          join: AudioRecording,
          on: AudioRecording.arel_table[:id].eq(Bookmark.arel_table[:audio_recording_id]),
          available: true
        }
      ]
    }
  end

  def self.schema
    {
      type: 'object',
      additionalProperties: false,
      properties: {
        id: { '$ref' => '#/components/schemas/id', readOnly: true },
        audio_recording_id: { '$ref' => '#/components/schemas/id' },
        name: { type: 'string' },
        category: { type: 'string' },
        offset_seconds: { type: 'number' },
        **Api::Schema.rendered_markdown(:description),
        **Api::Schema.updater_and_creator_ids_and_ats
      },
      required: [
        :id,
        :audio_recording_id,
        :name,
        :category,
        :offset_seconds,
        :description,
        :description_html,
        :description_html_tagline,
        :creator_id,
        :created_at,
        :updater_id,
        :updated_at
      ]
    }.freeze
  end
end
