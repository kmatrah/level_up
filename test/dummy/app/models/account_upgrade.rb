class AccountUpgrade < LevelUp::Job
  job do
    task :start, transitions: :upgrade
    task :upgrade, transitions: :email_notification
    task :email_notification, transitions: :end
  end

  def upgrade
    move_to :email_notification
  end

  def email_notification
    move_to :end
  end
end
