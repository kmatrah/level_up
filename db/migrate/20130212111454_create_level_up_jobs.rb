class CreateLevelUpJobs < ActiveRecord::Migration
  def change
    create_table :level_up_jobs do |t|
      t.string :type
      t.integer :delayed_job_id
      t.string :key
      t.string :state, default: "start"
      t.boolean :error, default: false
      t.boolean :timer, default: false
      t.boolean :task, default: false
      t.text :task_description
      t.datetime :failed_at
      t.string :failed_in
      t.text :backtrace
      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :canceled_at
      t.datetime :retry_at
      t.timestamps
    end

    add_index :level_up_jobs, :type
    add_index :level_up_jobs, :delayed_job_id
    add_index :level_up_jobs, :state
    add_index :level_up_jobs, :key
  end
end
