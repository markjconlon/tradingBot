class TradesController < ApplicationController
  def index
    @trades = Trade.all
  end

  def show
    @trade = Trade.find_by(params[:id])
  end

  def check_trades
    count = Trade.all.count
    until Trade.all.count > count
      liqui_response = HTTParty.get('https://api.liqui.io/api/3/depth/eth_btc?limit=10')
      poloniex_response = HTTParty.get('https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_ETH&depth=10')
      # quadrigacx_response = HTTParty.get('https://api.quadrigacx.com/public/orders?book=eth_btc&group=1')
      puts "//////////"
      puts Trade.all.count
      puts "/////////"
      x = Trade.check_trades(liqui_response, poloniex_response)

      puts liqui_response
      
      if !x
        break
      end
      sleep rand(5..10)
    end
  end
end
