class Api::V1::WalletController < ApplicationController
  
  
  ## This will will return the available wallets listings
  def getWallet

    # check user is loggin or not; if not loggin return the error
    current_user_id = current_user.id || 0

    posts = Transaction.where("user_id =?", "#{current_user_id}")
    transaction_count = Transaction.count
    total_cpa = User.calculateTotalCpa(current_user_id)
    render json: {data: posts, total: transaction_count, total_cpa: total_cpa}
  end

  def update
  end
end
