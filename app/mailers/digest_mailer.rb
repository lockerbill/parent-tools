class DigestMailer < ApplicationMailer
  # Takes child ids rather than report objects so it can be enqueued with
  # deliver_later (Active Job can only serialise simple types and AR records).
  def weekly(user, child_ids)
    @user = user
    @family = user.family
    @reports = @family.children.where(id: child_ids).map { |child| Dojo::ChildReport.new(child, days: 7) }

    mail subject: "#{@family.name}: this week in HomeDojo", to: user.email_address
  end
end
