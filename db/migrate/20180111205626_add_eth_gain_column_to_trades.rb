class AddEthGainColumnToTrades < ActiveRecord::Migration[5.1]
  def change
    add_column :trades, :eth_gain, :float
    add_column :trades, :total_eth_gain, :float
  end
end
