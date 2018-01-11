class TradesController < ApplicationController
  def index
    @trades = Trade.all
    @wallet_omg = 1
  end

  def show
    @trade = Trade.find_by(params[:id])
  end

  def check_trades
    CheckTradesJob.perform_later
  end
end
