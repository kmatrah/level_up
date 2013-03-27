require 'meta_search'
require 'delayed_job'
require 'delayed_job_active_record'
require 'kaminari'
require 'graphviz'

module LevelUp
  class Engine < ::Rails::Engine
    isolate_namespace LevelUp

    config.level_up = ::LevelUp::Configuration

    config.to_prepare do
      Mime::Type.register "image/svg+xml", :svg
    end
  end
end
