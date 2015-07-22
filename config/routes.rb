Rails.application.routes.draw do
 	post "/login" => "scraper#testing"
 	get '/login', :to => redirect('/login.html')
 	root :to => redirect('/index.html')
end
