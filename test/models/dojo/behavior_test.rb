require "test_helper"

module Dojo
  class BehaviorTest < ActiveSupport::TestCase
    test "needs-work behaviours always subtract" do
      behavior = family.behaviors.create!(name: "Shouting", points: 3, category: "needs_work", icon: "📣", color: "rose")

      assert_equal(-3, behavior.points)
      assert_equal "-3", behavior.signed_points
    end

    test "positive behaviours always add" do
      behavior = family.behaviors.create!(name: "Sharing", points: -2, category: "positive", icon: "🤝", color: "emerald")

      assert_equal 2, behavior.points
      assert_equal "+2", behavior.signed_points
    end

    test "zero-point behaviours are rejected" do
      behavior = family.behaviors.new(name: "Nothing", points: 0, category: "positive", icon: "😐", color: "slate")

      refute behavior.valid?
      assert_includes behavior.errors[:points].to_sentence, "other than"
    end

    test "archiving hides it from the picker but keeps past awards" do
      behavior = dojo_behaviors(:helping)
      before = behavior.point_events.count
      Dojo::PointEvent.award!(child: children(:ada), user: users(:owner), behavior: behavior)

      behavior.archive!

      refute_includes family.behaviors.active, behavior
      assert_equal before + 1, behavior.point_events.count
    end

    test "seeding gives a family a usable starter set" do
      fresh = Family.create!(name: "New family")
      Behavior.seed_defaults!(fresh)

      assert fresh.behaviors.positive.any?
      assert fresh.behaviors.needs_work.any?
      assert fresh.behaviors.needs_work.all? { |behavior| behavior.points.negative? }
    end
  end
end
