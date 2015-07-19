class ScraperController < ApplicationController

	require 'mechanize'
	require 'awesome_print'

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

			# Render the view
			render "testing"			
		else
			render :text => "Sorry, Login Failed. = ("
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

	# Log's a user into T-Square with their username and password.
	# Return the Dashboard page.
	def login(username, password)
	  @agent = Mechanize.new

	  # Open T-Square Log-in
	  @agent.get("https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")

	  # Submit Form
	  form = @agent.page.forms.first
	  form.username = username
	  form.password = password
	  form.submit
	end

	# Checks to see if login worked. Returns true if it worked, 
	# false otherwise.
	def authorized?
		if @agent.page.title.include?("T-Square") && @agent.page.title.include?("Home") && @agent.page.title.include?("Workspace")
			return true
		end
		return false
	end


	# Once logged in, uses the T-Square api to query for the 
	# current user's full name.
	def get_user_info  

	  @threads << Thread.new do 
	    agent = Mechanize.new
	    
	    # Open T-Square Log-in
	    agent.get("https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")

	    # Submit Form
	    form          = agent.page.forms.first
	    form.username = @username
	    form.password = @password
	    form.submit

	    json   = agent.get("https://t-square.gatech.edu/direct/user/current.json").body
	    result = JSON.parse json
	    
	    @user[:firstName] = result["firstName"]
	    @user[:lastName]  = result["lastName"]
	    @user[:id]        = result["id"]
	    @user[:email]     = result["email"]
	  end 
	end


	# Once the agent is in the dashboard, this method returns an array
	# of Mechanize links, for every class in the site navbar. Note, this
	# will only return actual classes like CS-1332, excluding group links.
	def get_classes  
	  @agent.page.links.each do |link|
	    info = Hash.new

	    if link.text.include?(@current_semester) && !link_present(link.uri.to_s)
	      info[:class] = (link.text.split(/[\t\n]/) - ["", " "])[0]
	      info[:id]    = link.uri.to_s.split("/").last
	      info[:link]  = link
	      @classes << info
	    end

	  end
	end

	# Helper method for get_classes
	def link_present(uri)
	   @classes.each do |cl|
	    if cl[:link].uri.to_s.include?(uri)
	      return true
	    end
	   end

	   return false
	end 


	# This method returns all the assignments for a given course. Note the course
	# input format must be in the form of a mechanize link. The out put is a hash
	# containing hashes for each assignment, with the title, open date, close date
	# and assignment status.
	def get_assignments_and_iframe course
	  
	  # Navigate to course page
	  course.click
	  assignments = []
	  info        = []

	  # null check for assignments page
	  if @agent.page.link_with(:text => "Assignments") != nil
	    
	    # Navigate to assignments page
	    @agent.page.link_with(:text => "Assignments").click
	    
	    # null check for iframe
	    if @agent.page.iframe != nil
	      
	      # Save the iframe URL
	      info << @agent.page.iframe.uri
	      @agent.page.iframe.click
	      
	      # null check for tables
	      if !@agent.page.search('td').text.empty? 
	        
	        # Get information from assignments table
	        td = @agent.page.search('td').text
	        td = td.split(/[\t\n]/)
	        td = td.reject {|item| item.blank?}
	        td = td.each_slice(5).to_a

	        td.each do |td|
	          hw          = {}
	          hw[:title]  = td[0]
	          hw[:status] = td[2]
	          hw[:open]   = td[3]
	          hw[:close]  = td[4]
	          assignments << hw
	        end
	      end
	    end
	  end

	  info << assignments
	  info
	end

end
