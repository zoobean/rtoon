require "bundler/gem_tasks"
require "rake/testtask"

desc "Compile Racc grammar"
task :racc do
  sh "racc -o lib/toon/parser.tab.rb lib/toon/parser.y"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: [:racc, :test]
