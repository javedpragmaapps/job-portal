class Api::V1::UserController < ApplicationController
  def index
    posts = User.all();
    render json: posts, status:200
  end

  def show
    render json: { error: "Inside show Action"}
  end

  def create
    render json: { error: "Inside create Action"}
  end

  def update
    render json: { error: "Inside update Action"}
  end

  def destroy
    render json: { error: "Inside destroy Action"}
  end
end
