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

ActiveRecord::Schema.define(:version => 20130815090135) do

  create_table "announcements", :force => true do |t|
    t.text     "message"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "consumer_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",       :limit => 30
    t.string   "token",      :limit => 1024
    t.string   "secret"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "consumer_tokens", ["token"], :name => "index_consumer_tokens_on_token", :unique => true, :length => {"token"=>100}

  create_table "credentials", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "url"
    t.string   "login"
    t.string   "password"
    t.string   "server_type"
    t.boolean  "in_use",      :default => false, :null => false
    t.boolean  "default",     :default => false, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "interaction_entries", :force => true do |t|
    t.string   "author_name"
    t.text     "content"
    t.string   "href"
    t.string   "in_reply_to"
    t.text     "input_data"
    t.string   "interaction_id"
    t.datetime "published"
    t.boolean  "response",               :default => false
    t.text     "result_data"
    t.string   "result_status"
    t.string   "run_id"
    t.string   "taverna_interaction_id"
    t.text     "title"
    t.datetime "updated"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  create_table "results", :force => true do |t|
    t.string   "name"
    t.string   "filetype"
    t.integer  "depth"
    t.integer  "run_id"
    t.string   "filepath"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "runs", :force => true do |t|
    t.string   "run_identification"
    t.string   "state"
    t.datetime "creation"
    t.datetime "start"
    t.datetime "end"
    t.datetime "expiry"
    t.integer  "workflow_id"
    t.string   "description"
    t.integer  "user_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "tavernaservs", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_statistics", :force => true do |t|
    t.integer  "run_count",          :default => 0
    t.integer  "mothly_run_average", :default => 0
    t.datetime "first_run_date"
    t.datetime "last_run_date"
    t.integer  "latest_workflow_id", :default => 0
    t.integer  "user_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "encrypted_password"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "admin",                  :default => false, :null => false
    t.string   "authentication_token"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean  "biovel",                 :default => false
    t.integer  "type_id",                :default => 1
    t.datetime "remember_created_at"
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "workflow_errors", :force => true do |t|
    t.integer  "workflow_id"
    t.string   "error_code"
    t.string   "my_experiment_id"
    t.string   "error_name"
    t.string   "error_pattern"
    t.string   "error_message"
    t.integer  "runs_count"
    t.integer  "ports_count"
    t.datetime "most_recent"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "workflow_ports", :force => true do |t|
    t.integer  "workflow_id"
    t.integer  "port_type"
    t.string   "name"
    t.string   "display_name"
    t.string   "display_description"
    t.integer  "order"
    t.integer  "port_value_type"
    t.string   "sample_value"
    t.string   "sample_file"
    t.string   "sample_file_type"
    t.boolean  "show"
    t.integer  "display_control_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "workflows", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.text     "description"
    t.string   "author"
    t.string   "workflow_file"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "my_experiment_id", :default => "0"
    t.float    "average_run",      :default => 0.0
    t.integer  "run_count",        :default => 0
    t.float    "slowest_run",      :default => 0.0
    t.datetime "slowest_run_date"
    t.float    "fastest_run",      :default => 0.0
    t.datetime "fastest_run_date"
    t.integer  "user_id",          :default => 0
    t.boolean  "shared",           :default => false
  end

end
