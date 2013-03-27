module LevelUp
  module HomeHelper
    def job_entry(job)
      link_to "#{job.key} @ #{I18n.l(job.created_at, format: :long)}", job_path(job)
    end
  end
end
