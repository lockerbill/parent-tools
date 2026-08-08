class Family < ApplicationRecord
  DEFAULT_SETTINGS = {
    "allow_negative_balance" => false,
    "week_start_day" => "monday",
    "kid_view_enabled" => true,
    "kid_requests_enabled" => true
  }.freeze

  WEEK_START_DAYS = %w[ monday sunday ].freeze

  has_many :users, dependent: :destroy
  has_many :children, -> { order(:position, :id) }, dependent: :destroy
  has_many :behaviors, -> { order(:position, :id) }, class_name: "Dojo::Behavior", dependent: :destroy
  has_many :rewards, -> { order(:position, :id) }, class_name: "Dojo::Reward", dependent: :destroy

  validates :name, presence: true, length: { maximum: 60 }

  # A single-family install is the v1 target, but every query is still scoped by
  # family_id so that multi-family support is an onboarding problem, not a rewrite.
  def self.current
    first
  end

  def self.installed?
    exists?
  end

  def settings
    DEFAULT_SETTINGS.merge(super || {})
  end

  def setting(key)
    settings[key.to_s]
  end

  def update_settings(new_settings)
    update(settings: settings.merge(new_settings.stringify_keys))
  end

  def allow_negative_balance?
    ActiveModel::Type::Boolean.new.cast(setting(:allow_negative_balance)) || false
  end

  def kid_view_enabled?
    ActiveModel::Type::Boolean.new.cast(setting(:kid_view_enabled)) || false
  end

  def kid_requests_enabled?
    kid_view_enabled? && (ActiveModel::Type::Boolean.new.cast(setting(:kid_requests_enabled)) || false)
  end

  def week_start_day
    day = setting(:week_start_day).to_s
    WEEK_START_DAYS.include?(day) ? day.to_sym : :monday
  end

  def owner
    users.owner.order(:id).first
  end
end
