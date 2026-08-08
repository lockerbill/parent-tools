class Child < ApplicationRecord
  COLORS = %w[ sky emerald amber rose violet teal orange indigo ].freeze

  has_secure_password :pin, validations: false

  belongs_to :family
  has_many :point_events, class_name: "Dojo::PointEvent", dependent: :destroy
  has_many :redemptions, class_name: "Dojo::Redemption", dependent: :destroy
  has_one_attached :avatar

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered, -> { order(:position, :id) }

  validates :name, presence: true, length: { maximum: 40 }
  validates :color, inclusion: { in: COLORS }
  validates :emoji, length: { maximum: 8 }, allow_blank: true
  validate :pin_is_four_to_six_digits

  before_validation :assign_position, on: :create

  attr_accessor :pin_confirmation

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  def pin?
    pin_digest.present?
  end

  def age
    return nil if birthdate.blank?

    now = Time.zone.today
    had_birthday = ([ now.month, now.day ] <=> [ birthdate.month, birthdate.day ]) >= 0
    now.year - birthdate.year - (had_birthday ? 0 : 1)
  end

  def initials
    name.to_s.split(/\s+/).filter_map { |part| part[0] }.first(2).join.upcase
  end

  # Applies a signed delta to the cached balance. Nothing is floored here on
  # purpose: the "never below zero" rule is enforced where points are *created*
  # (awards are clamped, redemptions are refused, reverts that would go negative
  # are refused), which keeps the cached counter an exact sum of the ledger.
  def apply_delta!(delta)
    update!(points_balance: points_balance + delta)
  end

  def would_go_negative?(delta)
    !family.allow_negative_balance? && (points_balance + delta).negative?
  end

  # The ledger is the source of truth; the cached balance is only an optimisation,
  # and the two are always exactly equal.
  def balance_from_ledger
    point_events.active.sum(:points) - redemptions.counted.sum(:cost)
  end

  def recalculate_balance!
    update_columns(points_balance: balance_from_ledger, updated_at: Time.current)
  end

  private
    def assign_position
      self.position = (family&.children&.maximum(:position) || 0) + 1 if position.to_i.zero?
    end

    def pin_is_four_to_six_digits
      return if pin.blank?

      errors.add(:pin, "must be 4 to 6 digits") unless pin.to_s.match?(/\A\d{4,6}\z/)
      errors.add(:pin_confirmation, "does not match") if pin_confirmation.present? && pin_confirmation != pin
    end
end
