class SessionsController < ApplicationController
  def new
    redirect_to '/auth/github'
  end
  def create
    auth = request.env["omniauth.auth"]
    if auth["info"]["nickname"].equals("xldenis")
      session[:logged_in]=true
    end
    redirect_to root_url
    
  end
end

