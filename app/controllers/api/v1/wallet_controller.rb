class Api::V1::WalletController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  ## This will will return the available wallets listings
  def getWallet
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    posts = Transaction.where("user_id =?", "#{current_user_id}")
    transaction_count = Transaction.count
    total_cpa = User.calculateTotalCpa(current_user_id)
    render json: {data: posts, total: transaction_count, total_cpa: total_cpa}
  end

  def update
  end

  ## this API will raise redeem request for the user's
  def redeemRequest

    ## fetch parameters from the payload
    redeemAmount = params[:redeemAmount]

    # check user is loggin or not; if not loggin return the error
    current_user_id = current_user.id || 0
    currentTotalCpa = User.calculateTotalCpa(current_user_id)

    # Calculate pending status amount for this user
    pendingTrnSum = calculatePendingTransactionSum(current_user_id)
    availableCpa = currentTotalCpa.to_i - pendingTrnSum.to_i;

    if (redeemAmount > availableCpa)
      render_json("Sorry, you do not have enough CPA points to redeem this amount.", 400, 'message') and return
    end


    ## get the transactionId
    transaction_id = generateTransactionId()
    
    # save the transaction details
    tempHash = {}
    tempHash["user_id"] = current_user_id
    tempHash["idd"] = current_user_id
    tempHash["redeemed_amount"] = redeemAmount
    tempHash["transaction_id"] = transaction_id
    new_transaction_id = Transaction.create(tempHash)
    render json: { message: "Transaction has been created successfully."}
  end

  ## suportive funcation to get the sum of redeemed_amount
  def calculatePendingTransactionSum(current_user_id)
    if(!current_user_id)
      render_json("Please provide the valid userId or login into the app.", 400, 'message') and return
    end

    results = Transaction.find_by_sql "select SUM(redeemed_amount) as sum from transactions
    where user_id = '#{current_user_id}'"
    result = results.pluck(:sum).join(',')
  end

  ## supportive funcation to Generate new transactionId 
  def generateTransactionId
    lastTransaction = Transaction.order("created_at DESC").limit(1).pluck(:transaction_id).join(',')
    if (lastTransaction)
      lastIdParts = lastTransaction.split("txn")
      if (lastIdParts.length === 2)
        lastIdNumber = lastIdParts[1].to_i + 1
        transaction_id = "txn0000000#{lastIdNumber}";
      else
        transaction_id = 'txn000000001';
      end
    else
      transaction_id = 'txn000000001';
    end
  end

  ## This API will be use to fetch the pending transactions
  def fetchPendingTransactions

    ## fetch params payload
    limit = params[:limit] || 25
    status = params[:status]

    ## get the list of transactions
    transaction_list = Transaction.where("status =?", "#{status}").limit(limit)

    ## get the total result count
    transactionTotal =  Transaction.count

    render json: {data: transaction_list, transactionTotal: transactionTotal}
  end

  def updateTransaction
    
    ## get parameters
    body = request.raw_post
    status = params[:status]
    transactionId = params[:id]

    transaction = Transaction.find_by(idd: transactionId)
    if !transaction
      render_json("Sorry, the transaction with ID: does not exist: #{transactionId}", 400, 'message') and return
    end
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    ## updating user's total cpa logic
    if (status === true) 
      pendingTrnSum = handleCPALogic(transactionId)
    end
    
    ## update body against the given id
    response = transaction.update(approved_by: current_user_id, approved_at: DateTime.now )
    render json: {data: transaction, message: 'Transaction updated successfully',}
  end


  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end

  private
  def handleCPALogic(transactionId)
    transactionIs = Transaction.find_by(idd: transactionId)
    if !transactionIs
      render_json("transactionId not exist.", 400, 'message') and return
    end

    ## get transaction data
    redeemed_amount =  transactionIs["redeemed_amount"]
    user_id =   transactionIs["user_id"]

    ## find current cpa amount
    currentTotalCPA = UsersCpa.find_by(userId: user_id)
    if !currentTotalCPA
      render_json("No records available in users_CPA table against the user_id.", 400, 'message') and return
    end

    ## get updated value of CPA
    current_total_cpa = currentTotalCPA["current_total_cpa"]
    puts current_total_cpa
    puts redeemed_amount
    if (current_total_cpa > redeemed_amount)
      updatedValueOfCurrentCpa = current_total_cpa - redeemed_amount
      currentTotalCPA.current_total_cpa = updatedValueOfCurrentCpa
      currentTotalCPA.save
    end
  end

end
