# frozen_string_literal: true

FactoryBot.define do
  factory :saved_search do
    sequence(:name) { |n| "saved search name #{n}" }
    sequence(:description) { |n| "saved search description #{n}" }
    sequence(:stored_query) { |_n| { uuid: { eq: 'blah blah' } } }

    creator

    trait :with_analysis_jobs do
      transient do
        analysis_job_count { 1 }
      end
      after(:create) do |saved_search, evaluator|
        raise 'Creator was blank' if evaluator.creator.blank?

        evaluator.analysis_job_count.times do
          saved_search.analysis_jobs << FactoryBot.create(:analysis_job, creator: evaluator.creator, saved_search: saved_search)
        end
      end
    end

    factory :saved_search_with_analysis_jobs, traits: [:with_analysis_jobs]

    factory :saved_search_with_projects do
      after(:create) do |saved_search, _evaluator|
        saved_search.projects << Project.all
      end
    end
  end
end
