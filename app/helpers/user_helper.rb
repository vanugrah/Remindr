module UserHelper
	# Checks if user exists in the database
	def new_user?
		if User.find_by(user_name: @username)
			return false 
		end
		return true
	end

	# Saves the user's details to database
	def save_user
		args              = Hash.new
		args[:user_ID]    = @user[:id]
		args[:user_name]  = @username
		args[:first_name] = @user[:firstName]
		args[:last_name]  = @user[:lastName]
		args[:email]      = @user[:email]
		
		salt                 = BCrypt::Engine.generate_salt
		encrypted            = BCrypt::Engine.hash_secret(@password, salt)
		args[:password_salt] = salt
		args[:password_hash] = encrypted

		new_user = User.new(args)
		new_user.save
	end
end