class Trade < ApplicationRecord

  has_one :wallet
  @our_volume_limit = 0.01 #ETH
  @margin = 0.0001

  def self.check_trades(liqui_response, poloniex_response)

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
    puts (high_sell[1][0] - (low_buy[1][0] * ((1 + 0.0025)/ ( 1 - 0.0026))))
    if high_sell[1][0] >= (low_buy[1][0] * ((1 + 0.0025)/ ( 1 - 0.0026)) + @margin)
      # if there is an opportunity we check to see which one has the lowest volume
      # this becomes the highest amount we can buy/sell
      find_highest_amount([high_sell, low_buy])
    end
  end

  def self.find_highest_amount(data)
    # data is in a format of [sellexchange: [rate, eth_amount], buyexchang: [rate, eth_amount]]
    if (data[0][1][1] < data[1][1][1])
      check_wallets([ data[0][0], data[0][1][0], data[1][0], data[1][1][0], data[0][1][1], Time.now ])
    else
      check_wallets( [ data[0][0], data[0][1][0], data[1][0], data[1][1][0], data[1][1][1], Time.now] )
    end
  end

  def self.check_wallets_after_trade
    liqui_post_url = 'https://api.liqui.io/tapi'
    poloniex_post_url = 'https://poloniex.com/tradingApi'

    nonce = Time.now().to_i + 2 #added + 1 incase it takes less than a second to get here
    wallet_command_poloniex = "command=returnAvailableAccountBalances&nonce=#{nonce}"
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

    liqui_eth = (liqui_wallet_response["return"]["funds"]["eth"]).to_f
    liqui_btc = (liqui_wallet_response["return"]["funds"]["btc"]).to_f
    poloniex_eth = (poloniex_wallet_response["exchange"]["ETH"]).to_f
    poloniex_btc = (poloniex_wallet_response["exchange"]["BTC"]).to_f

    return ([liqui_eth, liqui_btc, poloniex_eth, poloniex_btc])
  end

  def self.log_trade(data)
    start_time = Time.now().to_i

    if orders_fufilled
      Trade.create(sell_exchange: data[0], sell_exchange_rate: data[1], buy_exchange: data[2], buy_exchange_rate: data[3], trade_amount_eth: data[4])

      wallets = check_wallets_after_trade

      Wallet.create(trade_id: Trade.last.id, liqui_eth: wallets[0], liqui_btc: wallets[1], poloniex_eth: wallets[2], poloniex_btc: wallets[3])
      puts "orders fufilled"
      return true
    else
      Trade.create(sell_exchange: data[0], sell_exchange_rate: data[1], buy_exchange: data[2], buy_exchange_rate: data[3], trade_amount_eth: data[4])

      wallets = check_wallets_after_trade

      Wallet.create(trade_id: Trade.last.id, liqui_eth: wallets[0], liqui_btc: wallets[1], poloniex_eth: wallets[2], poloniex_btc: wallets[3])
      # halts trading for now, eventually will cancel one or both and handle trade + wallet accordingly.
      puts "orders not fufilled"
      return false

    end

  end

  def self.make_trade(data, liqui_wallet, poloniex_wallet)
    maximum_volume_available = data[4]
    sell_rate = data[1]
    buy_rate = data[3]

    liqui_post_url = 'https://api.liqui.io/tapi'
    poloniex_post_url = 'https://poloniex.com/tradingApi'

    nonce = Time.now().to_i + 1

    if maximum_volume_available > @our_volume_limit

      if data[0] == :sell_on_poloniex && data[2] == :buy_on_liqui

        sell_order_command_poloniex = "command=sell&currencyPair=BTC_ETH&rate=#{sell_rate}&amount=#{@our_volume_limit}&nonce=#{nonce}"
        buy_order_command_liqui= "nonce=#{nonce}&method=trade&pair=eth_btc&type=buy&rate=#{buy_rate}&amount=#{@our_volume_limit}"

        poloniex_sell_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['POLONIEX_SECRET'], sell_order_command_poloniex)
        liqui_buy_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['LIQUI_SECRET'], buy_order_command_liqui)

        poloniex_headers = {
          "key" => ENV['POLONIEX_KEY'],
          "sign" => poloniex_sell_signature,
          'Content-Type':  'application/x-www-form-urlencoded'
        }

        liqui_headers = {
          "key" => ENV['LIQUI_KEY'],
          "sign" => liqui_buy_signature,
          'Content-Type':  'application/x-www-form-urlencoded'
        }

        # COMMENT OR UNCOMMENT IF YOU WANT IT TO ACTUALLY MAKE TRADES
        poloniex_sell_wallet_response = HTTParty.post(poloniex_post_url, body: sell_order_command_poloniex, headers: poloniex_headers)
        liqui_buy_wallet_response = HTTParty.post(liqui_post_url, body: buy_order_command_liqui, headers: liqui_headers)
        puts "SELL ON POLONIEX AND BUY ON LIQUI"
        puts poloniex_sell_wallet_response
        puts liqui_buy_wallet_response
        log_trade(data)

      elsif data[0] == :sell_on_liqui && data[2] == :buy_on_poloniex

        sell_order_command_liqui= "nonce=#{nonce}&method=trade&pair=eth_btc&type=sell&rate=#{sell_rate}&amount=#{@our_volume_limit}"
        buy_order_command_poloniex = "command=buy&currencyPair=BTC_ETH&rate=#{buy_rate}&amount=#{@our_volume_limit}&nonce=#{nonce}"

        liqui_sell_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['LIQUI_SECRET'], sell_order_command_liqui)
        poloniex_buy_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['POLONIEX_SECRET'], buy_order_command_poloniex)

        liqui_headers = {
          "key" => ENV['LIQUI_KEY'],
          "sign" => liqui_sell_signature,
          'Content-Type':  'application/x-www-form-urlencoded'
        }

        poloniex_headers = {
          "key" => ENV['POLONIEX_KEY'],
          "sign" => poloniex_buy_signature,
          'Content-Type':  'application/x-www-form-urlencoded'
        }

        # COMMENT OR UNCOMMENT IF YOU WANT IT TO ACTUALLY MAKE TRADES
        liqui_sell_wallet_response = HTTParty.post(liqui_post_url, body: sell_order_command_liqui, headers: liqui_headers)
        poloniex_buy_wallet_response = HTTParty.post(poloniex_post_url, body: buy_order_command_poloniex, headers: poloniex_headers)
        puts "SELL ON LIQUI AND BUY ON POLONIEX"
        puts liqui_sell_wallet_response
        puts poloniex_buy_wallet_response
        log_trade(data)

      end

    end

  end

  def self.orders_fufilled
    liqui_post_url = 'https://api.liqui.io/tapi'
    poloniex_post_url = 'https://poloniex.com/tradingApi'

    nonce = Time.now().to_i

    open_order_command_liqui= "nonce=#{nonce}&method=activeOrders"
    open_order_command_poloniex = "command=returnOpenOrders&currencyPair=BTC_ETH&nonce=#{nonce}"

    poloniex_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['POLONIEX_SECRET'], open_order_command_poloniex)
    liqui_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), ENV['LIQUI_SECRET'], open_order_command_liqui)

    poloniex_headers = {
    "key" => ENV['POLONIEX_KEY'],
    "sign" => poloniex_signature,
    'Content-Type':  'application/x-www-form-urlencoded'
    }

    liqui_headers = {
    "key" => ENV['LIQUI_KEY'],
    "sign" => liqui_signature,
    'Content-Type':  'application/x-www-form-urlencoded'
    }

    poloniex_open_trades_response = HTTParty.post(poloniex_post_url, body: open_order_command_poloniex, headers: poloniex_headers)
    liqui_open_trades_response = HTTParty.post(liqui_post_url, body: open_order_command_liqui, headers: liqui_headers)

    if poloniex_open_trades_response.empty? && liqui_open_trades_response["return"].empty?
      return true
    else
      puts "waiting for orders to fill"
      return false
    end
  end

  def self.check_wallets(data)
    liqui_post_url = 'https://api.liqui.io/tapi'
    poloniex_post_url = 'https://poloniex.com/tradingApi'

    nonce = Time.now().to_i
    wallet_command_poloniex = "command=returnAvailableAccountBalances&nonce=#{nonce}"
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

    liqui_ether = (liqui_wallet_response["return"]["funds"]["eth"]).to_f
    poloniex_ether = (poloniex_wallet_response["exchange"]["ETH"]).to_f

    # simple solution for now this could check which one is selling ether first thereby allowing us to
    # make a trade if it is the the right direction
    if liqui_ether >= @our_volume_limit && poloniex_ether >= @our_volume_limit
      make_trade(data, liqui_wallet_response, poloniex_wallet_response)

    else
      puts "WALLETS NEED REBALANCING"
      return false
    end

  end
end
