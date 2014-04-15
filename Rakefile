require 'rake'
require 'rake/testtask'
require 'iron_hide/couchdb_tasks'

Rake::TestTask.new do |t|
  t.test_files = FileList['app.rb']
  t.verbose    = true
end

task :default => :test
