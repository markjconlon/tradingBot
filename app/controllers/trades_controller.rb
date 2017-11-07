class TradesController < ApplicationController
  def index
    @trades = Trade.all
  end

  def show
    @trade = Trade.find_by(params[:id])
  end

  def check_trades
    until Trade.all.count > 3
      liqui_response = HTTParty.get('https://api.liqui.io/api/3/depth/eth_btc?limit=10')
      poloniex_response = HTTParty.get('https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_ETH&depth=10')
      sleep 2
      puts liqui_response.body
      puts poloniex_response.body
      puts "//////////"
      puts Trade.all.count
      puts "/////////"
      Trade.check_trades(liqui_response, poloniex_response)
      sleep rand(5..10)
    end
  end
end
