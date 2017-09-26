class CreateTrades < ActiveRecord::Migration[5.1]
  def change
    create_table :trades do |t|
      t.string :sell_exchange
      t.string :buy_exchange
      t.float :sell_exchange_rate
      t.float :buy_exchange_rate
      t.float :delta
      t.float :trade_amount_eth

      t.timestamps
    end
  end
end
