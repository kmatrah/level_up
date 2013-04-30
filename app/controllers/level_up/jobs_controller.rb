require_dependency 'level_up/application_controller'

module LevelUp
  class JobsController < ApplicationController
    if Configuration.http_authentication
      http_basic_authenticate_with name: Configuration.http_login, password: Configuration.http_password
    end

    def index
      @search_params = params[:search] || {}
      @query_params = @search_params.dup

      if @query_params[:delayed_job_id_eq] == 'true'
        @query_params[:delayed_job_id_is_not_null] = true
      elsif @query_params[:delayed_job_id_eq] == 'false'
        @query_params[:delayed_job_id_is_null] = true
      end
      @query_params.delete :delayed_job_id_eq

      @search = Job.search(@query_params)
      @jobs = @search.relation.page(params[:page]).per(20)
    end

    def show
      @job = Job.find params[:id]
    end

    def edit
      @job = Job.find params[:id]
    end

    def update
      @job = Job.find params[:id]
      if @job.update_attributes(params[:job])
        redirect_to job_path(@job), notice: 'Changes saved!'
      else
        render :edit
      end
    end

    def destroy
      job = Job.find params[:id]
      job.destroy
      redirect_to jobs_path, notice: "Job destroyed!"
    end

    def unqueue
      job = Job.find params[:id]
      job.unqueue!
      redirect_to job_path(job), notice: 'Unqueued!'
    end

    def run
      job = Job.find params[:id]
      job.boot!(nil, false, false)
      redirect_to job_path(job), notice: 'Run!'
    end

    def reboot
      job = Job.find params[:id]
      if job.boot_async!
        redirect_to job_path(job), notice: 'Rebooted!'
      else
        flash[:error] = 'Error while rebooting'
        redirect_to job_path(job)
      end
    end

    def move
      job = Job.find params[:id]
      if job.boot_async!(params[:task])
        redirect_to job_path(job), notice: "Moved to #{params[:task]}!"
      else
        flash[:error] = "Error while moving to #{params[:task]}"
        redirect_to job_path(job)
      end
    end

    respond_to :svg
    def graphviz
      job = Job.find params[:id]

      if job
        builder = GraphBuilder.new(job)
        graph = builder.graph
        graph.output(:svg => "#{Rails.root}/tmp/job_#{job.id}.svg")
        send_data(File.open("#{Rails.root}/tmp/job_#{job.id}.svg").read, filename: "job_#{job.id}.svg", type: 'image/svg+xml', disposition: 'inline')
      else
        render text: "Job not found", status: 404
      end
    end
  end
end
