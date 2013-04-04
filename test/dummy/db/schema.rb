# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130404201329) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "level_up_jobs", :force => true do |t|
    t.string   "type"
    t.integer  "delayed_job_id"
    t.string   "key"
    t.string   "task",                    :default => "start"
    t.boolean  "error",                   :default => false
    t.boolean  "timer",                   :default => false
    t.boolean  "manual_task",             :default => false
    t.text     "manual_task_description"
    t.datetime "failed_at"
    t.string   "failed_in"
    t.text     "backtrace"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "canceled_at"
    t.datetime "retry_at"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "level_up_jobs", ["delayed_job_id"], :name => "index_level_up_jobs_on_delayed_job_id"
  add_index "level_up_jobs", ["key"], :name => "index_level_up_jobs_on_key"
  add_index "level_up_jobs", ["task"], :name => "index_level_up_jobs_on_task"
  add_index "level_up_jobs", ["type"], :name => "index_level_up_jobs_on_type"

end
