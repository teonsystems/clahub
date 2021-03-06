class ApplicationController < ActionController::Base

  before_filter :set_common_variables

  protect_from_forgery

  private

  def sign_in(user)
    session[:user_id] = user.id
  end

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end
  helper_method :current_user

  def signed_in?
    !!current_user
  end
  helper_method :signed_in?

  def signed_out?
    !signed_in?
  end

  def sign_out
    session[:user_id] = nil
  end

  def set_common_variables
    @CLAHUB_CONFIG = $CLAHUB_CONFIG
  end
end
