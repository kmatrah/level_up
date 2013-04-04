class AccountDowngrade < LevelUp::Job
  job do
    task :start, transitions: :account_validation
    task :account_validation, transitions: [:account_update, :service_delete]
    task :account_update, transitions: [:service_delete, :mail_suspension]
    task :mail_suspension, transitions: :service_update
    task :service_update, transitions: :waiting_renewal
    task :waiting_renewal, transitions: [:manual_deletion, :mail_activation]
    task :manual_deletion, transitions: :account_update
    task :service_delete, transitions: :mail_activation
    task :mail_activation, transitions: :end
  end
end
