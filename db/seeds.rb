# Seeds are idempotent and safe to run at any time.
#
# In production the first-boot wizard at /setup creates the family, the owner
# account and the starter behaviours and rewards, so this file normally does
# nothing. In development it gives you a family to click around in:
#
#   bin/rails db:seed
#
# Set DEMO=1 to also generate a couple of weeks of point history.

if Family.installed?
  puts "Family already exists — nothing to seed."
else
  family = Family.create!(name: "The Demo Family")

  User.create!(
    family: family,
    name: "Demo Parent",
    email_address: "parent@example.com",
    password: "homedojo123",
    password_confirmation: "homedojo123",
    role: "owner"
  )

  Dojo::Behavior.seed_defaults!(family)
  Dojo::Reward.seed_defaults!(family)

  [
    { name: "Ada",  color: "violet",  emoji: "🦊", pin: "1234" },
    { name: "Bo",   color: "emerald", emoji: "🐢", pin: "2345" },
    { name: "Cleo", color: "amber",   emoji: "🐝" }
  ].each { |attrs| family.children.create!(attrs) }

  puts "Seeded #{family.name}: sign in as parent@example.com / homedojo123"
end

family = Family.current
behaviors = family&.behaviors&.active&.to_a || []

if ENV["DEMO"].present? && behaviors.any? && Dojo::PointEvent.none?
  parent = family.owner

  family.children.active.find_each do |child|
    40.times do
      behavior = behaviors.sample
      Dojo::PointEvent.award!(
        child: child,
        user: parent,
        behavior: behavior,
        occurred_at: rand(0..20).days.ago - rand(0..12).hours
      )
    end
  end

  puts "Added demo point history."
elsif ENV["DEMO"].present?
  puts "Skipping DEMO history: there are already point events (or no behaviours to award)."
end
