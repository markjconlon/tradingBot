class CreateWallets < ActiveRecord::Migration[5.1]
  def change
    create_table :wallets do |t|
      t.references :trade, foreign_key: true
      t.float :liqui_btc
      t.float :liqui_eth
      t.float :poloniex_btc
      t.float :poloniex_eth

      t.timestamps
    end
  end
end
