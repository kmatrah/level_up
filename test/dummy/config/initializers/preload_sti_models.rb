if Rails.env.development?
  %w[account_banish account_downgrade account_upgrade].each do |job_type|
    require_dependency File.join("app","models", "#{job_type}.rb")
  end
end