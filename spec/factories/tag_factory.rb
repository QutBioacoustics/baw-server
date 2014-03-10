require 'faker'

FactoryGirl.define do

  factory :tag do |f|
    sequence(:text) { |n| "#{Faker::Lorem.word}#{n}" }

    creator

    trait :taxonomic do
      is_taxanomic true
    end

    trait :random_type do
      type_of_tag Tag::AVAILABLE_TYPE_OF_TAGS.sample
    end

    trait :retired do
      retired true
    end

    trait :notes do
      notes { {Faker::Lorem.word => Faker::Lorem.word} }
    end

    factory :tag_random, traits: [:random_type]
    factory :tag_random_taxonomic, traits: [:random_type, :taxonomic]
    factory :tag_random_retired, traits: [:random_type, :retired]


  end
end

