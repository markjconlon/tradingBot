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

ActiveRecord::Schema.define(version: 20180111213609) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "trades", force: :cascade do |t|
    t.string "sell_exchange"
    t.string "buy_exchange"
    t.float "sell_exchange_rate"
    t.float "buy_exchange_rate"
    t.float "delta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "volume_in_omg"
    t.float "eth_gain"
    t.float "total_eth_gain"
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "trade_id"
    t.float "liqui_eth"
    t.float "poloniex_eth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "liqui_omg"
    t.float "poloniex_omg"
    t.index ["trade_id"], name: "index_wallets_on_trade_id"
  end

  add_foreign_key "wallets", "trades"
end
