module Dojo
  class Redemption < ApplicationRecord
    belongs_to :child
    belongs_to :reward, class_name: "Dojo::Reward"
    belongs_to :user, optional: true # the approving parent

    enum :status, {
      requested: "requested",
      approved: "approved",
      denied: "denied",
      fulfilled: "fulfilled"
    }, validate: true

    # Statuses that have actually taken points off the balance.
    COUNTED_STATUSES = %w[ approved fulfilled ].freeze

    scope :counted, -> { where(status: COUNTED_STATUSES) }
    scope :pending, -> { where(status: "requested") }
    scope :recent, -> { order(created_at: :desc, id: :desc) }

    validates :cost, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :note, length: { maximum: 500 }, allow_blank: true

    validate :child_can_afford_it, on: :create, if: :charging_on_create?

    class << self
      # Parent taps a reward for a child: approved and deducted in one step.
      def redeem!(child:, reward:, user:, note: nil)
        transaction do
          child.reload
          redemption = create!(child: child, reward: reward, user: user, cost: reward.cost,
                               status: "approved", note: note, decided_at: Time.current)
          child.apply_delta!(-redemption.cost)
          redemption
        end
      end

      # Kid taps "Request" on the tablet: nothing is deducted until a parent approves.
      def request!(child:, reward:, note: nil)
        create!(child: child, reward: reward, cost: reward.cost, status: "requested", note: note)
      end
    end

    def approve!(user)
      approved = false

      self.class.transaction do
        reload
        child.reload
        next unless requested?
        next if child.would_go_negative?(-cost)

        update!(status: "approved", user: user, decided_at: Time.current)
        child.apply_delta!(-cost)
        approved = true
      end

      approved
    end

    # Every state change re-reads the row inside the transaction: two parents
    # tapping Approve and Decline at the same moment must not both win.
    def deny!(user)
      denied = false

      self.class.transaction do
        reload
        next unless requested?

        update!(status: "denied", user: user, decided_at: Time.current)
        denied = true
      end

      denied
    end

    # Marking as given is bookkeeping only — the points already left the balance.
    def fulfill!(user)
      fulfilled = false

      self.class.transaction do
        reload
        next unless approved?

        update!(status: "fulfilled", user: user, fulfilled_at: Time.current)
        fulfilled = true
      end

      fulfilled
    end

    # Undo a redemption: the points go back and the row is marked denied.
    def cancel!
      cancelled = false

      self.class.transaction do
        reload
        next unless COUNTED_STATUSES.include?(status)

        child.reload
        child.apply_delta!(cost)
        update!(status: "denied", decided_at: Time.current)
        cancelled = true
      end

      cancelled
    end

    def decided?
      !requested?
    end

    private
      def charging_on_create?
        COUNTED_STATUSES.include?(status)
      end

      def child_can_afford_it
        return if child.blank? || cost.blank?
        return if child.family.allow_negative_balance?
        return if child.points_balance >= cost

        errors.add(:base, "#{child.name} needs #{cost - child.points_balance} more points for this reward")
      end
  end
end
