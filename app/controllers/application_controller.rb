class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Need CAS Authorization to access main app
	before_filter CASClient::Frameworks::Rails::Filter

  def hello

  	 render text: "Hello World!"
  end
end
