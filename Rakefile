# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :gem do
  desc "Build the gem"
  task :build do
    sh "gem build quantitative.gemspec"
  end

  desc "Tag the release in git"
  task :tag do
    version = Quant::VERSION
    sh "git tag -a v#{version} -m 'Release #{version}'"
    sh "git push origin v#{version}"
  end

  desc "Install local *.gem file"
  task :install do
    sh "gem install quantitative-#{Quant::VERSION}.gem"
  end

  desc "Remove local *.gem files"
  task :clean do
    sh "rm -f quantitative-#{Quant::VERSION}.gem"
  end

  desc "Release #{Quant::VERSION} to rubygems.org"
  task release: [:build, :tag] do
    sh "gem push quantitative-#{Quant::VERSION}.gem"
  end

  desc "push #{Quant::VERSION} to rubygems.org"
  task push: [:build] do
    sh "gem push quantitative-#{Quant::VERSION}.gem"
  end
end
