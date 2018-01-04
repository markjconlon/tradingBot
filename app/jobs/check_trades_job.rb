class CheckTradesJob < ApplicationJob
  queue_as :default

  def perform(*args)
    now = Time.now().to_i
    count = Trade.all.count
    time_to_run = 1800
    until Trade.all.count > count + 2
      begin
        liqui_response = HTTParty.get('https://api.liqui.io/api/3/depth/omg_eth?limit=10')
      rescue Errno::ETIMEDOUT, Net::OpenTimeout, Errno::ECONNRESET, OpenSSL::SSL::SSLError
        puts "liqui rescue"
        retry
      end
      begin
        poloniex_response = HTTParty.get('https://poloniex.com/public?command=returnOrderBook&currencyPair=ETH_OMG&depth=10')
      rescue Errno::ETIMEDOUT, Net::OpenTimeout, Errno::ECONNRESET, OpenSSL::SSL::SSLError
        puts "poloniex rescue"
        retry
      end
      # quadrigacx_response = HTTParty.get('https://api.quadrigacx.com/public/orders?book=eth_btc&group=1')
      puts "//////////"
      puts Trade.all.count
      puts "/////////"
      x = Trade.check_trades(liqui_response, poloniex_response)

      # puts liqui_response

      if x == false
        break
      end
      sleep rand(5..10)
    end
  end
end
