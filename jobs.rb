require 'rest-client'

class SendEmail
  def self.perform(job)
  	# Future code for loading html template
	# file = File.open("path-to-file.tar.gz", "txt")
	# contents = file.read
	begin
		RestClient.post "https://api:key-6iqs3vfdn7pnkgxpj4ip4-1iyve-ljm3"\
		"@api.mailgun.net/v2/sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org/messages",
		"from" => "GitHub Reminder <postmaster@sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org>",
		"to" => "Stephen Russett <stephenrussett@gmail.com>",
		"subject" => "GitHub Reminder - #{Time.now}",
		"text" => "This is a Github-Reminder"

		puts "email was sent"
	rescue
		puts "something went wrong when email was attempted"
	end
  end
end



class CheckIfReminder
	def self.preform(job)


	end
end


class ParseReminder
	def self.preform(job)


	end
end


class ValidateUserPermissions
	def self.preform(job)

		# 1. Hook Registered ,active, and public?
		# 2. User has access to the hook?
		# 3. User has registered the repo and is active

	end
end


class ScheduleEmail
	def self.preform(job)

		# client = Qless::Client.new
		# queue = client.queues['testing']
		# queue.put(MyJobClass, {:hello => 'howdy'}, :delay => 420)
	end
end

