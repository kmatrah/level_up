require_dependency "level_up/application_controller"

module LevelUp
  class HomeController < ApplicationController
    if Configuration.http_authentication
      http_basic_authenticate_with name: Configuration.http_login, password: Configuration.http_password
    end

    def index
      @metrics = {created: {}, started: {}, ended: {}, canceled: {}}
      [:created, :started, :ended, :canceled].each do |type|
        start_date = Date.today - 1.month
        values = LevelUp::Job.where(created_at: start_date..Date.today).order(:created_at).group("DATE(#{type}_at)").count

        while start_date != Date.today do
          @metrics[type][start_date.to_s] = values[start_date.to_s] ? values[start_date.to_s] : 0
          start_date += 1.day
        end
      end
    end
  end
end
