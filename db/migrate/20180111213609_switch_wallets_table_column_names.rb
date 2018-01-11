class SwitchWalletsTableColumnNames < ActiveRecord::Migration[5.1]
  def change
    remove_column :wallets, :liqui_btc, :float
    remove_column :wallets, :poloniex_btc, :float
    add_column :wallets, :liqui_omg, :float
    add_column :wallets, :poloniex_omg, :float
  end
end
