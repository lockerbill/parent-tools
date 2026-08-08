module Dojo
  class Behavior < ApplicationRecord
    CATEGORIES = %w[ positive needs_work ].freeze
    COLORS = %w[ emerald sky violet amber orange rose slate teal ].freeze

    belongs_to :family
    has_many :point_events, class_name: "Dojo::PointEvent", dependent: :nullify

    enum :category, { positive: "positive", needs_work: "needs_work" }, validate: true

    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }
    scope :ordered, -> { order(:position, :id) }

    validates :name, presence: true, length: { maximum: 60 }
    validates :points, presence: true,
                       numericality: { only_integer: true, other_than: 0, greater_than_or_equal_to: -100, less_than_or_equal_to: 100 }
    validates :icon, presence: true, length: { maximum: 8 }
    validates :color, inclusion: { in: COLORS }

    before_validation :normalize_points
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

    def signed_points
      points.positive? ? "+#{points}" : points.to_s
    end

    # Seeded on first boot; every one of these is editable or archivable.
    DEFAULTS = [
      { name: "Helping at home",  points: 2,  category: "positive",   icon: "🧹", color: "emerald" },
      { name: "Homework done",    points: 3,  category: "positive",   icon: "📚", color: "sky" },
      { name: "Kind to sibling",  points: 2,  category: "positive",   icon: "💞", color: "rose" },
      { name: "Ready on time",    points: 1,  category: "positive",   icon: "⏰", color: "violet" },
      { name: "Great manners",    points: 1,  category: "positive",   icon: "🙏", color: "teal" },
      { name: "Teasing",          points: -2, category: "needs_work", icon: "😠", color: "rose" },
      { name: "Not listening",    points: -1, category: "needs_work", icon: "🙉", color: "amber" },
      { name: "Screen overrun",   points: -2, category: "needs_work", icon: "📱", color: "orange" },
      { name: "Left a mess",      points: -1, category: "needs_work", icon: "🧦", color: "slate" }
    ].freeze

    def self.seed_defaults!(family)
      DEFAULTS.each_with_index do |attrs, index|
        family.behaviors.create!(attrs.merge(position: index + 1))
      end
    end

    private
      # "needs work" behaviours always subtract, positive ones always add, no
      # matter which sign the parent typed into the form.
      def normalize_points
        return if points.blank?

        self.points = points.abs
        self.points = -points if needs_work?
      end

      def assign_position
        self.position = (family&.behaviors&.maximum(:position) || 0) + 1 if position.to_i.zero?
      end
  end
end
