module Dojo
  class Reward < ApplicationRecord
    belongs_to :family
    has_many :redemptions, class_name: "Dojo::Redemption", dependent: :restrict_with_error

    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }
    scope :ordered, -> { order(:position, :id) }
    scope :affordable_for, ->(child) { where(cost: ..child.points_balance) }

    validates :name, presence: true, length: { maximum: 60 }
    validates :cost, presence: true,
                     numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10_000 }
    validates :icon, presence: true, length: { maximum: 8 }

    before_validation :assign_position, on: :create

    def archived?
      archived_at.present?
    end

    def archive!
      update!(archived_at: Time.current)
    end

    def restore!
      update!(archived_at: nil)
    end

    def affordable_for?(child)
      child.points_balance >= cost
    end

    DEFAULTS = [
      { name: "30 min extra screen time", cost: 20, icon: "📺" },
      { name: "Choose Friday movie",      cost: 30, icon: "🍿" },
      { name: "Pick dinner",              cost: 40, icon: "🍝" },
      { name: "Stay up 30 min late",      cost: 35, icon: "🌙" },
      { name: "Trip to the park",         cost: 50, icon: "🛝" }
    ].freeze

    def self.seed_defaults!(family)
      DEFAULTS.each_with_index do |attrs, index|
        family.rewards.create!(attrs.merge(position: index + 1))
      end
    end

    private
      def assign_position
        self.position = (family&.rewards&.maximum(:position) || 0) + 1 if position.to_i.zero?
      end
  end
end
