module Dojo
  # An immutable ledger row. "Undo" stamps reverted_at and reverses the balance
  # instead of deleting, so the history a family looks back on stays honest.
  #
  # Invariant: child.points_balance == sum(active events) - sum(counted redemptions).
  # It holds because every path that could break it is closed at the source —
  # awards are clamped, redemptions are refused, and a revert that would drive
  # the balance below zero is refused.
  class PointEvent < ApplicationRecord
    UNDO_WINDOW = 24.hours

    belongs_to :child
    belongs_to :behavior, class_name: "Dojo::Behavior", optional: true
    belongs_to :user, optional: true

    scope :active, -> { where(reverted_at: nil) }
    scope :reverted, -> { where.not(reverted_at: nil) }
    scope :recent, -> { order(occurred_at: :desc, id: :desc) }
    scope :occurred_between, ->(from, to) { where(occurred_at: from..to) }

    validates :points, presence: true, numericality: { only_integer: true }
    validates :requested_points, presence: true,
                                 numericality: { only_integer: true, other_than: 0 }
    validates :label, presence: true, length: { maximum: 80 }
    validates :note, length: { maximum: 500 }, allow_blank: true
    validates :occurred_at, presence: true

    class << self
      # The core loop. Creating an event and moving the cached balance happen in
      # one transaction so the two can never disagree.
      def award!(child:, user: nil, behavior: nil, points: nil, note: nil, label: nil, occurred_at: nil)
        requested = (points.presence || behavior&.points).to_i
        raise ArgumentError, "a behaviour or a non-zero point value is required" if requested.zero?

        transaction do
          child.reload
          applied = clamp(requested, child)

          event = create!(
            child: child,
            user: user,
            behavior: behavior,
            points: applied,
            requested_points: requested,
            label: label.presence || behavior&.name || "Manual adjustment",
            note: note.presence,
            occurred_at: occurred_at || Time.current
          )

          child.apply_delta!(applied)
          event
        end
      end

      def award_many!(children:, **options)
        transaction { children.map { |child| award!(child: child, **options) } }
      end

      private
        # With "never go below zero" on, a deduction can only take away what the
        # child actually has. The full request is still recorded for reporting.
        def clamp(requested, child)
          return requested if requested.positive?
          return requested if child.family.allow_negative_balance?

          # Clamp against the non-negative part of the balance only. If the
          # family turned negative balances off while a child was already below
          # zero, a deduction must stay a deduction of at most nothing — never
          # flip into an award.
          spendable = [ child.points_balance, 0 ].max
          [ requested, -spendable ].max
        end
    end

    def reverted?
      reverted_at.present?
    end

    def undoable?
      !reverted? && occurred_at > UNDO_WINDOW.ago
    end

    # Returns false when the undo is not allowed — already undone, outside the
    # window, or it would push the child below zero (they have already spent it).
    def revert!
      reverted = false

      self.class.transaction do
        reload
        child.reload
        next if reverted? || !undoable? || child.would_go_negative?(-points)

        update!(reverted_at: Time.current)
        child.apply_delta!(-points)
        reverted = true
      end

      reverted
    end

    def clamped?
      points != requested_points
    end

    def signed_points
      points.positive? ? "+#{points}" : points.to_s
    end

    # Classified by what the parent asked for, not by what survived clamping —
    # a deduction against a zero balance is still a deduction.
    def positive?
      requested_points.positive?
    end

    def icon
      behavior&.icon || (positive? ? "✨" : "⚠️")
    end

    def color
      behavior&.color || (positive? ? "emerald" : "rose")
    end
  end
end
