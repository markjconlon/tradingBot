class RemoveTradeAmountEthFromTrades < ActiveRecord::Migration[5.1]
  def change
    remove_column :trades, :trade_amount_eth, :float
    add_column :trades, :volume_in_omg, :float
  end
end
