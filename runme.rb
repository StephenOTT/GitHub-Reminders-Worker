require 'qless/tasks'

require 'qless'
require 'qless/job_reservers/ordered'
require 'qless/worker'
require_relative 'jobs'
		
queues = %w[ testing ].map { |name| Qless::Client.new.queues[name] }
# queues = "testing"
job_reserver = Qless::JobReservers::Ordered.new(queues)
worker = Qless::Workers::ForkingWorker.new(job_reserver, :num_workers => 1, :interval => 20).run
