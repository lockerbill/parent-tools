namespace :dojo do
  desc "Recompute every child's cached points balance from the ledger"
  task recalculate_balances: :environment do
    Child.find_each do |child|
      before = child.points_balance
      child.recalculate_balance!
      after = child.reload.points_balance

      if before == after
        puts "  ok      #{child.name}: #{after}"
      else
        puts "  fixed   #{child.name}: #{before} -> #{after}"
      end
    end
  end
end

namespace :homedojo do
  desc "Set a new password for a parent account: rake homedojo:reset_password EMAIL=... PASSWORD=..."
  task reset_password: :environment do
    email = ENV["EMAIL"].to_s.strip.downcase
    password = ENV["PASSWORD"].to_s

    abort "EMAIL is required" if email.blank?
    abort "PASSWORD must be at least 10 characters" if password.length < 10

    user = User.find_by(email_address: email)
    abort "No account for #{email}" if user.nil?

    user.update!(password: password, password_confirmation: password)
    user.sessions.destroy_all
    puts "Password updated for #{user.email_address}. Existing sessions signed out."
  end

  desc "List parent accounts"
  task users: :environment do
    User.includes(:family).find_each do |user|
      puts "#{user.email_address}\t#{user.role}\t#{user.name}\t(#{user.family.name})"
    end
  end

  desc "Back up the SQLite databases and Active Storage files into storage/backups"
  task backup: :environment do
    require "fileutils"

    stamp = Time.current.utc.strftime("%Y%m%d-%H%M%S")
    target = Rails.root.join("storage", "backups", stamp)
    FileUtils.mkdir_p(target)

    Dir[Rails.root.join("storage", "*.sqlite3")].each do |path|
      name = File.basename(path)
      system("sqlite3", path, ".backup '#{target.join(name)}'") ||
        abort("sqlite3 CLI not available — install it or copy storage/ while the app is stopped")
      puts "  backed up #{name}"
    end

    blobs = Rails.root.join("storage")
    Dir[blobs.join("??")].each do |dir|
      FileUtils.cp_r(dir, target)
    end

    puts "Backup written to #{target}"
  end

  desc "Send the weekly digest now (requires SMTP_ADDRESS)"
  task digest: :environment do
    abort "Set SMTP_ADDRESS to enable digests" if ENV["SMTP_ADDRESS"].blank?
    WeeklyDigestJob.perform_now
    puts "Digest sent."
  end
end
