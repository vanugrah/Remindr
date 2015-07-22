class ScraperController < ApplicationController

  # Ignore CSRF for individual actions
	protect_from_forgery :except => [:testing]

	def testing
		# Set login params and variables
		@username         = params[:Username]
		@password         = params[:Password]
		@current_semester = "SPR15"
		@user             = Hash.new
		@classes          = Array.new
		@threads          = Array.new

		# Login into T-Square
		login(@username, @password)

		if authorized?
			# Start scraping
			main_task

			# Wait for all child processes to finish
			@threads.each do |thread|
				thread.join
			end

			# Checks for new user
			if new_user?
				save_user
			end

			# Render the view
			render "testing"			
		else
			redirect_to "/login", :notice => "Sorry, something went wrong with your username or password. Have another go?"
		end
	end

	def main_task
		# Gets links to all current classes
		get_classes

		# Get all assignment info for each class
		@classes.each do |cl|
			@threads << Thread.new do 
				
				info = get_assignments_and_iframe cl[:link]
				
				cl[:iframe]      = info[0]
				cl[:assignments] = info[1]
			end
		end

		# Gets userName, id, email
		get_user_info
	end

end
