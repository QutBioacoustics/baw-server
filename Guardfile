# More info at https://github.com/guard/guard#readme
notification :off

guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  #watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
  #
  ## Rails specs
  #watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  #watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/models/(.+)\.rb$})                    { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| [ "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { 'spec' }
  watch('config/routes.rb')                           { 'spec/routing' }
  watch('app/controllers/application_controller.rb')  { 'spec/acceptance' }
  #watch(%r{^spec/factories/(.+)\.rb$})                { %w(spec/acceptance spec/features spec/models) }

  # Capybara features specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/features/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| "spec/features/#{m[1]}_spec.rb" }
  watch(%r{^app/models/(.+)\.rb$})                    { |m| "spec/features/#{m[1]}s_spec.rb" }

  # for external modules
  watch(%r{^lib/external/harvester/(.+)\.rb$})        { |m| 'spec/externals/harvester_spec.rb' }
  watch(%r{^lib/modules/(.+)\.rb$})                   { |m| "spec/externals/#{m[1]}_spec.rb" }

  ## Turnip features and steps
  #watch(%r{^spec/acceptance/(.+)\.feature$})
  #watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
end

