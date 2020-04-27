require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :typecheck do
    sh "srb"
end

task :test do
    ruby "./test/run.rb"
end

task :default => [:typecheck, :spec, :test]
