
namespace :maintenance do
    desc "Run cleanup tasks"
    task cleanup: :environment do
      puts "Running cleanup tasks..."
      CleanupJob.perform_now
      puts "Cleanup completed!"
    end
  
    desc "Send daily summaries"
    task daily_summaries: :environment do
      puts "Sending daily summaries..."
      DailySummaryJob.perform_now
      puts "Daily summaries sent!"
    end
  
    desc "Check for expiring produce"
    task check_expiring: :environment do
      puts "Checking for expiring produce..."
      ProduceExpiryJob.perform_now
      puts "Expiring produce check completed!"
    end
  end