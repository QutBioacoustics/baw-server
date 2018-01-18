class CreateDatasetsV2 < ActiveRecord::Migration
  def change
    create_table :datasets do |t|

      t.string :name
      t.text :description
      t.integer :creator_id
      t.timestamps null: false

    end
    create_table :dataset_items do |t|

      t.integer :dataset_id
      t.integer :audio_recording_id
      t.decimal :start_time_seconds       , :null => false
      t.decimal :end_time_seconds       , :null => false
      t.decimal :order
      t.timestamps null: false

    end
    create_table :progress_events do |t|

      t.integer :user_id
      t.integer :dataset_item_id
      t.string :activity
      t.datetime :created_at

    end

    add_foreign_key :dataset_items, :datasets
    add_foreign_key :progress_events, :dataset_items
    add_foreign_key :progress_events, :users
    add_foreign_key :dataset_items, :audio_recordings
    add_foreign_key :datasets, :users, column: :creator_id

    add_index(:dataset_items, [:start_time_seconds, :end_time_seconds], unique: false, name: 'dataset_items_idx')

  end
end
