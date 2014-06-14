require 'chronic'
require_relative 'accepted_emoji'

module Helpers

	def self.get_Reminder_Emoji
		return Accepted_Emoji.accepted_reminder_emoji
	end

	def self.get_time_work_date(parsedTimeComment, userTimezone, commentCreated_At)
		# userTimezone sample: Eastern Time (US & Canada) -05:00
		# We strip out the space and -05:00 from the end of the string.
		Time.zone = userTimezone[0..-8]
		Chronic.time_class = Time.zone
		return Chronic.parse(parsedTimeComment, :now => Chronic.parse(commentCreated_At))
	end

	def self.parse_billable_time_comment(timeComment, timeEmoji)
		return timeComment.gsub("#{timeEmoji} ","").split(" | ")
	end

	def self.get_time_commit_comment(parsedTimeComment)
		return parsedTimeComment.lstrip.gsub("\r\n", " ")
	end


	def self.reminder_comment?(commentBody)
		acceptedReminderEmoji = Accepted_Emoji.accepted_reminder_emoji

		acceptedReminderEmoji.any? { |w| commentBody =~ /\A#{w}/ }
	end

end