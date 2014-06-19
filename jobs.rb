require 'rest-client'
require_relative 'reminder_validation/controller'
require 'qless'
require_relative 'mongo'
require 'json'
require 'logger'
require 'erubis'

class SendEmail
  def self.perform(job)
  	# Future code for loading html template
	# file = File.open("path-to-file.tar.gz", "txt")
	# contents = file.read
	# begin
		RestClient.post "https://api:#{ENV["MAILGUN_API_KEY"]}"\
		"@api.mailgun.net/v2/#{ENV["MAILGUN_API_DOMAIN"]}/messages",
		"from" => "GitHub-Reminder <github-reminder-no-reply@github-reminders.com>",
		"to" => job.data["toEmail"],
		"subject" => job.data["subject"],
		"html" => job.data["body"]

	# rescue
		# puts "something went wrong when we tried to send the the reminder email"
	# end
  end
end

class MongoQueries

		def self.mongo_connection(clearCollections = false)
			Mongo_Connection.mongo_Connect("localhost", 27017, ENV['MONGO_DB_NAME'], ENV['MONGO_DB_COLL_NAME'])

			if clearCollections == true
			Mongo_Connection.clear_mongo_collections
			end
		end

		def self.aggregate(input)
			self.mongo_connection
			Mongo_Connection.aggregate(input)
		end


		# Checks MongoDB to see if the user has a record/profile based on the userid
		def self.get_user_profile(userid)
			userProfile = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$project" => {_id:0, userid: 1, email:1, name:1, timezone:1, username:1}}
									])
			
			profileCount = userProfile.count
			
			if profileCount == 1
				return userProfile[0]
			elsif profileCount > 1
				return "Oh oh, something went wrong. Multiple user counts were found that match your user ID."
			elsif profileCount == 0
				return "We could not find a user profile that matches your User ID"
			end
		end


		# Checks MongoDB to see if the user has a record/profile based on the userid
		def self.user_exists?(userid)
			users = self.aggregate([
									{ "$match" => {userid: userid}}
									]).count
			if users >= 1
				return true
			elsif users == 0 or users == nil
				return false
			elsif users > 1
				return "Something went wrong... duplicate users have found in our records..."
			end
		end

		# Returns true if the repo is already registered under the specific users
		def self.repo_registered?(userid, repo)
			repo = repo.downcase
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$registered_repos"},
									# { "$project" => {"registered_repos.repo" => {"$toLower"=>"$registered_repos.repo"}}},
									{ "$match" => {"registered_repos.repo" => repo}}
									]).count
									# ])
			if repos == 1
				return true
			elsif repos == 0
				return false
			elsif repos > 1
				# TODO add logic on app.rb side to account for the error message response.
				return "Something went wrong...duplicate registered repository records have been found...."		
			end
		end


		# Checks mongoDB for registered hooks for the user.
		def self.reminder_hook_exists_in_mongo?(userid, repo)
			repo = repo.downcase
			# TODO add logic for checking is repo exists regardless of whether they are owner of webhook
			hooks = self.aggregate([
									# { "$match" => {userid: userid}},
									{ "$unwind" => "$registered_hooks"},
									# { "$project" => {"registered_hooks.repo" => {"$toLower"=>"$registered_hooks.repo"}}},
									{ "$match" => {"registered_hooks.repo" => repo}}
									]).count

			if hooks == 1
				return true
			elsif hooks == 0
				return false
			elsif hooks > 1
				# TODO add logic on app.rb side to account for the error message response.
				return "Something went wrong...duplicate registered hook records have been found...."		
			end
		end
end

class CheckIfReminder
	def self.perform(job)
		# TODO Rebuld this methid as it is WAY to big and to many 
		# components are in this single method		

		commentData = JSON.parse(job.data["comment"])
		commentBody = commentData["comment"]["body"]
		userid = commentData["comment"]["user"]["id"]
		commentCreated_At = commentData["comment"]["created_at"]

		issueNumber = commentData["issue"]["number"]
		issueTitle = commentData["issue"]["title"]
		commentID = commentData["comment"]["id"]
		repoName = commentData["repository"]["name"]
		repoFullName = commentData["repository"]["full_name"]

		job.tag("UserID=#{userid}",
				"FullRepoName=#{repoFullName.downcase}",
				"issueNumber=#{issueNumber}",
				"commentNumber=#{commentID}",
				"UserAndRepo=#{userid}/#{repoFullName.downcase}",
				"UserAndRepoAndIssue=#{userid}/#{repoFullName.downcase}/#{issueNumber}",
				"UserAndRepoAndIssueAndComment=#{userid}/#{repoFullName.downcase}/#{issueNumber}/#{commentID}",
				)


		isReminderTF = ReminderValidation.is_Reminder_Comment?(commentBody)

		if  isReminderTF == false
			puts "Not a Reminder Comment"
		
		elsif isReminderTF == true
			puts "Is a Reminder Comment"


			hookExistsTF = MongoQueries.reminder_hook_exists_in_mongo?(userid, repoFullName)
			if hookExistsTF == true


				userExistsTF = MongoQueries.user_exists?(userid)

				if userExistsTF == true
					userProfile = MongoQueries.get_user_profile(userid)
						userTimezone = userProfile["timezone"]
						userToEmail = userProfile["email"]
						userName = userProfile["name"]


					# Validates that the user who created the comment has the repo registered
					repoRegisteredTF = MongoQueries.repo_registered?(userid, repoFullName)
					if repoRegisteredTF == true
					# TODO Validation of Hook for Repo

						parsedReminder = ReminderValidation.process_request(commentData, userTimezone)	
						
						if parsedReminder.class == Hash

							delayTime = parsedReminder[:scheduled_date].to_f - Time.strptime(commentCreated_At, '%Y-%m-%dT%H:%M:%S%z').utc.to_f
							reminderDateTime = parsedReminder[:scheduled_date]
							reminderComment = parsedReminder[:time_comment]



							emailTemplate = File.read("./email_templates/reminder.html.erb")
							emailTemplate = Erubis::Eruby.new(emailTemplate)
							emailBody = emailTemplate.result(:issueNumber => issueNumber,
														:issueTitle => issueTitle,
														:commentID => commentID,
														:commentBody => commentBody,
														:commentCreated_At => commentCreated_At,
														:repoFullName => repoFullName,
														:repoName => repoName,
														:reminderDateTime => reminderDateTime,
														:reminderComment => reminderComment,
														:userTimezone => userTimezone,
														:userName => userName,
														:userToEmail => userToEmail,
														)


							client = Qless::Client.new(:url => ENV["REDIS_URL"])
							queue = client.queues['testing']
							queue.put(SendEmail, { :parentValidationJobId => job.jid,
													:toEmail => userToEmail,
													:body => emailBody,
													:subject => "GitHub-Reminder: #{repoFullName} issue: #{issueNumber}"
													}, 
													:delay => delayTime,
													:tags => job.tags
													)
						end
					elsif repoRegisteredTF == false
						puts "user did not have the repo registered"		
					end
				elsif userExistsTF == false
					puts "user does not have a account"
				end

			elsif hookExistsTF == false
				puts "hook does not exist"
			end

		end
	end
end


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

