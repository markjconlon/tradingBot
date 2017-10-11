class Trade < ApplicationRecord
  def self.check_trades(liqui_response, poloniex_response)
    # liqui_response = HTTParty.get('https://api.liqui.io/api/3/depth/eth_btc?limit=10')
    # quadrigacx_response = HTTParty.get('https://api.quadrigacx.com/public/orders?book=eth_btc&group=1')
    # poloniex_response = HTTParty.get('https://poloniex.com/public?command=returnOrderBook&currencyPair=BTC_ETH&depth=10')
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
  end
end
