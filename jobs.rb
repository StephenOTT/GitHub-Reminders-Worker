require 'rest-client'
# require_relative 'reminder_validation/controller'
require 'qless'
# require_relative 'mongo'

class SendEmail
  def self.perform(job)
  	# Future code for loading html template
	# file = File.open("path-to-file.tar.gz", "txt")
	# contents = file.read
	# begin
		RestClient.post "https://api:#{ENV["MAILGUN_API_KEY"]}"\
		"@api.mailgun.net/v2/#{ENV["MAILGUN_API_DOMAIN"]}/messages",
		"from" => "GitHub-Reminder <github-reminder-no-reply@samples.mailgun.org>",
		"to" => job.data[:toEmail],
		"subject" => job.data[:subject],
		"text" => job.data[:body]
		
	# rescue
		# puts "something went wrong when we tried to send the the reminder email"
	# end
  end
end



# class CheckIfReminder
# 	def self.preform(job)
# 		# TODO rebuild this method so it chains multiple jobs together
# 		commentAttrs = job.data[:comment].attrs
		
# 		if ReminderValidation.is_Reminder_Comment?(commentAttrs[:comment].attrs[:body]) == false
# 			return "Not a Reminder Comment"
		
# 		elsif ReminderValidation.is_Reminder_Comment?(commentAttrs[:comment].attrs[:body]) == true
			
# 			# TODO Validation of Hook for Repo
# 			# TODO Validation of Repo for user

# 			# if hook and repo for user is validated then
# 				userTimezone = nil # Get user's timezone from mongo
# 				userToEmail = nil # Get user's selected email from mongo
# 				calcDelay = nil # Calculate the number of seconds between the Comment Created_At DateTime and the Reminder DataTime
# 				username = nil
# 				repo = nil
# 				tags = nil


# 			parsedRemidner = ReminderValidation.process_request(job.data[:comment].attrs, userTimezone)	
			


# 			if parsedRemidner.class == Hash
# 				generatedSubject = nil
# 				generatedBody = nil

# 				client = Qless::Client.new(:url => ENV["REDIS_URL"])
# 				queue = client.queues['Email']
# 				queue.put(SendEmail, {:toEmail => job.data[:toEmail],
# 										:body => jobs.data[:body],
# 										:subject => job.data[:subject]
# 										}, 
# 										:delay => job.data[:delay],
# 										:tags => ["User|#{job.data[:username]}",
# 												 "Repo|#{job.data[:repo]}",
# 												 "Issue|#{job.data[:issueNumber]}"])
# 			end
# 		end		
# 	end
# end


# class ParseReminder
# 	def self.preform(job)
# 		# TODO add error handling based on reposes from process request/Parse_time_commit
# 		ReminderValidation.process_request(job.data[:comment].attrs, userTimezone)

# 	end
# end


# class ValidateUserPermissions
# 	def self.preform(job)

# 		# 1. Hook Registered ,active, and public?
# 		# 2. User has access to the hook?
# 		# 3. User has registered the repo and is active

# 	end
# end


# class ScheduleEmail
# 	def self.preform(job)

# 		# client = Qless::Client.new
# 		# queue = client.queues['testing']
# 		# queue.put(MyJobClass, {:hello => 'howdy'}, :delay => 420)
# 	end
# end

