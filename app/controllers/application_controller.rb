class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :logged_in?
  private
  	def logged_in?
  		return true if session[:logged_in]
  	end
end
