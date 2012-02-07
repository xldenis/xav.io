class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :logged_in?
  private
  	def logged_in?
  		unless session[:logged_in]
        redirect_to root_url
        return false
      end
  	end
end
