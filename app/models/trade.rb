class Trade < ApplicationRecord
  def self.check_trades(liqui_response, poloniex_response)
    # liqui_response = HTTParty.get('https://api.liqui.io/api/3/depth/eth_btc?limit=10')
    # quadrigacx_response = HTTParty.get('https://api.quadrigacx.com/public/orders?book=eth_btc&group=1')
    # poloniex_response = HTTParty.get('https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_ETH&depth=10')

    # calls to the apis are made on in the controller and passed down

    return if liqui_response["success"] == 0
    liqui_sell = liqui_response["eth_btc"]["asks"][0]
    liqui_buy = liqui_response["eth_btc"]["bids"][0]
    poloniex_sell = [(poloniex_response["asks"][0][0]).to_f, poloniex_response["asks"][0][1]]
    poloniex_buy = [(poloniex_response["bids"][0][0]).to_f, poloniex_response["bids"][0][1]]

    top_trades = { sells:
      { sell_on_liqui: liqui_buy,
        sell_on_poloniex: poloniex_buy },
        buys:
        { buy_on_liqui: liqui_sell,
          buy_on_poloniex: poloniex_sell}
        }
    profitable_trade(top_trades)
  end

  def self.find_highest_sell(sells)
    (sells.max_by{|k,v| v})
  end

  def self.find_lowest_buy(buys)
    (buys.min_by{|k,v| v})
  end

  def self.profitable_trade(trades)
    # determines which exchange has the highest sell and lowest buy
    # then we check if the difference is in our margin
    high_sell = find_highest_sell(trades[:sells])
    low_buy = find_lowest_buy(trades[:buys])
    if high_sell[1][0] <= (low_buy[1][0] * ((1 + 0.0025)/ ( 1 - 0.0026)))
      # if there is an opportunity we check to see which one has the lowest volume
      # this becomes the highest amount we can buy/sell
      find_highest_amount([high_sell, low_buy])
    end
  end

  def self.find_highest_amount(data)
    # data is in a format of [sellexchange: [rate, eth_amount], buyexchang: [rate, eth_amount]]
    if (data[0][1][1] < data[1][1][1])
      write_to_table([ data[0][0], data[0][1][0], data[1][0], data[1][1][0], data[0][1][1], Time.now ])
    else
      write_to_table( [ data[0][0], data[0][1][0], data[1][0], data[1][1][0], data[1][1][1], Time.now] )
    end
  end

  def self.check_wallets(data)
    liqui_post_url = 'https://api.liqui.io/tapi'
    poloniex_post_url = 'https://poloniex.com/tradingApi'

    nonce = Time.now().to_i
    wallet_command_poloniex = "command=returnBalances&nonce=#{nonce}"
    wallet_command_liqui= "nonce=#{nonce}&method=getInfo"

    liqui_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['LIQUI_SECRET'], wallet_command_liqui)
    poloniex_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['POLONIEX_SECRET'], wallet_command_poloniex)

    liqui_headers = {
    "key" => ENV['LIQUI_KEY'],
    "sign" => liqui_signature,
    'Content-Type':  'application/x-www-form-urlencoded'
    }

    poloniex_headers = {
    "key" => ENV['POLONIEX_KEY'],
    "sign" => poloniex_signature,
    'Content-Type':  'application/x-www-form-urlencoded'
    }

    liqui_wallet_response = HTTParty.post(liqui_post_url, body: wallet_command_liqui, headers: liqui_headers)
    poloniex_wallet_response = HTTParty.post(poloniex_post_url, body: wallet_command_poloniex, headers: poloniex_headers)

    puts liqui_wallet_response, poloniex_wallet_response
  end

  def self.write_to_table(data)
    Trade.create(sell_exchange: data[0], sell_exchange_rate: data[1], buy_exchange: data[2], buy_exchange_rate: data[3], trade_amount_eth: data[4])
    check_wallets(data)
  end
end
