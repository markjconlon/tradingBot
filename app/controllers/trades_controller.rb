class TradesController < ApplicationController
  def index
    @trades = Trade.all
  end

  def show
    @trade = Trade.find_by(params[:id])
  end

  CheckTradesJob.perform_later
  def check_trades
  end
end
