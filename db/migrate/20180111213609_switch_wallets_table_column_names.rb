class SwitchWalletsTableColumnNames < ActiveRecord::Migration[5.1]
  def change
    remove_column :trades, :liqui_btc, :float
    remove_column :trades, :poloniex_btc, :float
    add_column :trades, :liqui_omg, :float
    add_column :trades, :poloniex_omg, :float
  end
end
