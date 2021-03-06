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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_02_235533) do

  create_table "data", force: :cascade do |t|
    t.text "doc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "days", force: :cascade do |t|
    t.date "shift_day"
    t.integer "qastaff_id"
    t.integer "breakstaff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rests", force: :cascade do |t|
    t.integer "staff_id"
    t.integer "group_id"
    t.integer "wcp_train_flag"
    t.float "working_hour"
    t.date "day"
    t.integer "rest_time"
    t.datetime "rest_start"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shifts", force: :cascade do |t|
    t.datetime "start"
    t.datetime "end"
    t.string "air_staff_id"
    t.date "date"
    t.integer "group_id"
    t.integer "staff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "staffs", force: :cascade do |t|
    t.string "name"
    t.string "air_staff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "train_shifts", force: :cascade do |t|
    t.integer "staff_id"
    t.datetime "start"
    t.datetime "end"
    t.string "which"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
