require 'faker'
include ActionDispatch::TestProcess

FactoryGirl.define do

  factory :script do
    sequence(:name) { |n| "#{Faker::Name.title}#{n}"}
    sequence(:analysis_identifier) { |n| "#{Faker::Lorem.word}#{n}"}
    sequence(:version) { |n| n * 0.01}
    settings_file { fixture_file_upload(Rails.root.join('public', 'files','script', 'settings_file.txt'), 'text/plain') }

    creator

    trait :notes do
      notes { {Faker::Lorem.word => Faker::Lorem.paragraph} }
    end

    trait :verified do
      verified true
    end

    trait :description do
      description { Faker::Lorem.paragraph }
    end

    trait :data do
      data_file { fixture_file_upload(Rails.root.join('public', 'files','script', 'settings_file.txt'), 'text/plain') }
    end

  end
end