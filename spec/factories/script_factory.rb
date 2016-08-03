include ActionDispatch::TestProcess

FactoryGirl.define do

  factory :script do
    sequence(:name) { |n| "script name #{n}"}
    sequence(:description) { |n| "script description #{n}" }
    sequence(:analysis_identifier) { |n| "script machine identifier #{n}"}
    sequence(:version) { |n| n * 0.01}
    sequence(:executable_command) { |n| "executable command #{n}"}
    sequence(:executable_settings) { |n| "executable settings #{n}"}
    sequence(:executable_settings_media_type) { |n| 'text/plain' }
    sequence(:analysis_action_params) { |n| {
        file_executable: './AnalysisPrograms/AnalysisPrograms.exe',
        copy_paths: [
            './programs/AnalysisPrograms/Logs/log.txt'
        ],
        custom_setting: n
    }}

    creator

    trait :verified do
      verified true
    end
  end
end