# frozen_string_literal: true

FactoryBot.define do
  factory :dataset do
    sequence(:name) { |n| "gen_dataset_name#{n}" }
    sequence(:description) { |n| "dataset description #{n}" }

    creator
  end
end
