class Initial < ActiveRecord::Migration
  def up
    create_table "experimenter_assignments", :force => true do |t|
      t.integer  "user_id"
      t.integer  "experiment_id"
      t.string   "rights"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end

    create_table "experiments", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.text     "contact"
      t.string   "sender_email"
      t.boolean  "finished"
      t.string   "auto_participation_key"
      t.boolean  "show_in_stats",               :default => true
      t.boolean  "show_in_calendar",            :default => true
      t.integer  "participations_count"
      t.boolean  "registration_active",         :default => false
      t.string   "invitation_subject",          :default => "Einladung zum Experiment"
      t.text     "invitation_text"
      t.datetime "invitation_start"
      t.integer  "invitation_size"
      t.integer  "invitation_hours"
      t.boolean  "invitation_prefer_new_users", :default => false
      t.boolean  "reminder_enabled",            :default => false
      t.string   "reminder_subject"
      t.text     "reminder_text"
      t.integer  "reminder_hours",              :default => 48
      t.string   "confirmation_subject",        :default => "Anmeldebestätigung"
      t.text     "confirmation_text"
      t.datetime "created_at",                                                          :null => false
      t.datetime "updated_at",                                                          :null => false
    end

    create_table "history_entries", :force => true do |t|
      t.text     "filter_settings"
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
      t.integer  "experiment_id"
      t.string   "action"
      t.integer  "user_count"
      t.text     "user_ids"
    end

    create_table "locations", :force => true do |t|
      t.string   "name"
      t.string   "description"
      t.boolean  "active",      :default => true
      t.datetime "created_at",                    :null => false
      t.datetime "updated_at",                    :null => false
    end

    create_table "login_codes", :force => true do |t|
      t.integer  "user_id"
      t.string   "code"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    add_index "login_codes", ["user_id"], :name => "index_login_codes_on_user_id"

    create_table "messages", :force => true do |t|
      t.string   "subject"
      t.integer  "sender_id"
      t.integer  "experiment_id"
      t.text     "message"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
      t.integer  "session_id"
    end

    create_table "participations", :force => true do |t|
      t.integer  "experiment_id"
      t.integer  "user_id"
      t.integer  "filter_id"
      t.datetime "invited_at"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end

    add_index "participations", ["experiment_id"], :name => "index_participations_on_experiment_id"
    add_index "participations", ["user_id"], :name => "index_participations_on_user_id"

    create_table "recipients", :force => true do |t|
      t.integer  "message_id"
      t.integer  "user_id"
      t.datetime "sent_at"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "session_participations", :force => true do |t|
      t.integer  "session_id"
      t.integer  "user_id"
      t.datetime "reminded_at"
      t.boolean  "showup",       :default => false, :null => false
      t.boolean  "participated", :default => false, :null => false
      t.boolean  "noshow",       :default => false, :null => false
      t.datetime "created_at",                      :null => false
      t.datetime "updated_at",                      :null => false
    end

    add_index "session_participations", ["session_id"], :name => "index_session_participations_on_session_id"
    add_index "session_participations", ["user_id"], :name => "index_session_participations_on_user_id"

    create_table "sessions", :force => true do |t|
      t.integer  "experiment_id"
      t.integer  "location_id"
      t.integer  "reference_session_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.text     "description"
      t.integer  "needed",               :default => 20
      t.integer  "reserve",              :default => 3
      t.integer  "group_size"
      t.text     "limitations"
      t.boolean  "reminder_enabled",     :default => false
      t.string   "reminder_subject"
      t.text     "reminder_text"
      t.integer  "reminder_hours",       :default => 48
      t.integer  "time_before",          :default => 0
      t.integer  "time_after",           :default => 0
      t.datetime "created_at",                              :null => false
      t.datetime "updated_at",                              :null => false
    end

    add_index "sessions", ["experiment_id"], :name => "index_sessions_on_experiment_id"
    add_index "sessions", ["reference_session_id"], :name => "index_sessions_on_reference_session_id"

    create_table "settings", :force => true do |t|
      t.string   "var",                       :null => false
      t.text     "value"
      t.integer  "target_id"
      t.string   "target_type", :limit => 30
      t.datetime "created_at",                :null => false
      t.datetime "updated_at",                :null => false
    end

    add_index "settings", ["target_type", "target_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

    create_table "taggings", :force => true do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.integer  "tagger_id"
      t.string   "tagger_type"
      t.string   "context",       :limit => 128
      t.datetime "created_at"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

    create_table "tags", :force => true do |t|
      t.string "name"
    end

    create_table "users", :force => true do |t|
      t.string   "email",                              :default => "",     :null => false
      t.string   "encrypted_password",                 :default => "",     :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                      :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string   "firstname"
      t.string   "lastname"
      t.string   "role",                               :default => "user", :null => false
      t.string   "calendar_key"
      t.boolean  "deleted",                            :default => false
      t.integer  "begin_month_old"
      t.integer  "begin_year_old"
      t.integer  "preference"
      t.boolean  "experience"
      t.integer  "noshow_count",                       :default => 0
      t.integer  "participations_count",               :default => 0
      t.string   "secondary_email"
      t.datetime "secondary_email_confirmed_at"
      t.string   "secondary_email_confirmation_token"
      t.boolean  "show_greeting",                      :default => true
      t.boolean  "account_paused",                     :default => false
      t.boolean  "imported",                           :default => false
      t.boolean  "activated_after_import",             :default => false
      t.string   "import_token"
      t.string   "import_email"
      t.string   "import_email_confirmation_token"
      t.datetime "created_at",                                             :null => false
      t.datetime "updated_at",                                             :null => false
      t.string   "gender"
      t.date     "birthday"
      t.string   "phone"
      t.string   "country_name"
      t.string   "matrikel"
      t.text     "language"
      t.date     "begin_of_studies"
      t.text     "degree"
      t.text     "profession"
      t.text     "course_of_studies"
    end

    add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
    add_index "users", ["deleted"], :name => "index_users_on_deleted"
    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
    add_index "users", ["role"], :name => "index_users_on_role"
    
  end

  def down
  end
end
