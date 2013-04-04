module LevelUp
  module HomeHelper
    def job_entry(job)
      if job
        link_to "#{job.key} @ #{I18n.l(job.created_at, format: :long)}", job_path(job)
      else
        '-'
      end
    end
  end
end
