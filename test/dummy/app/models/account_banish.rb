class AccountBanish < LevelUp::Job
  job do
    task :start, transitions: :banish
    task :banish, transitions: [:check_account, :email_notification]
    task :check_account, transitions: [:banish, :report]
    task :report, transitions: :end
    task :email_notification, transitions: :end
  end


  def banish
    move_to :email_notification
  end

  def email_notification
    move_to :end
  end
end
