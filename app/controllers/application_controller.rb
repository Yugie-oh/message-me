class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?
  before_action :sync_cable_user

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_user
    return if logged_in?

    redirect_to login_path, flash: { error: "You must be logged in to perform that action" }
  end

  def log_in(user)
    session[:user_id] = user.id
    @current_user = user
    cookies.encrypted[:user_id] = { value: user.id, httponly: true }
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
    cookies.delete(:user_id)
  end

  private

  def sync_cable_user
    cookies.encrypted[:user_id] = { value: current_user.id, httponly: true } if logged_in?
  end
end
