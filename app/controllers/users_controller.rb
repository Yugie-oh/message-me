class UsersController < ApplicationController
  before_action :require_user

  def index
    @users = User.where.not(id: current_user.id).order(:username)
  end
end
