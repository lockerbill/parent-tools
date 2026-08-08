# Optional. Nothing schedules this by default — digests are off unless you set
# SMTP_ADDRESS and add an entry to config/recurring.yml. See the README.
class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    return if ENV["SMTP_ADDRESS"].blank?

    Family.find_each do |family|
      child_ids = family.children.active.pluck(:id)
      next if child_ids.empty?

      reports = child_ids.map { |id| Dojo::ChildReport.new(Child.find(id), days: 7) }
      next if reports.all?(&:empty?)

      family.users.where(role: %w[ owner parent ]).find_each do |user|
        # Only ids cross the job boundary: a report object is not serialisable.
        DigestMailer.weekly(user, child_ids).deliver_later
      end
    end
  end
end
