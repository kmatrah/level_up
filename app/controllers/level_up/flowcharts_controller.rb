require_dependency 'level_up/application_controller'

module LevelUp
  class FlowchartsController < ApplicationController
    if Configuration.http_authentication
      http_basic_authenticate_with name: Configuration.http_login, password: Configuration.http_password
    end

    def index
      @job_classes = LevelUp::Job.descendants.map { |klass| klass }
    end

    def show
      @job_type = params[:id]
      @job_class = @job_type.camelize.safe_constantize
      if @job_class

      else
        flash.now[:alert] = "Job class not found"
      end
    end

    respond_to :svg
    def graphviz
      job_type = params[:id]
      job_class = job_type.camelize.safe_constantize

      if job_class
        builder = GraphBuilder.new(job_class)
        graph = builder.graph
        graph.output(:svg => "#{Rails.root}/tmp/#{job_type}.svg")
        send_data(File.open("#{Rails.root}/tmp/#{job_type}.svg").read, filename: "#{job_type}.svg", type: 'image/svg+xml', disposition: 'inline')
      else
        render text: "Job class not found", status: 404
      end
    end
  end
end
