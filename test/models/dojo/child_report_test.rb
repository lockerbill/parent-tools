require "test_helper"

module Dojo
  class ChildReportTest < ActiveSupport::TestCase
    setup do
      @child = children(:bo)
      @user = users(:owner)
      @child.point_events.destroy_all
      @child.update!(points_balance: 0)
    end

    test "the daily series covers every day in the window, including empty ones" do
      report = ChildReport.new(@child, days: 30)

      assert_equal 30, report.daily_series.size
      assert_equal Time.zone.today, report.daily_series.last.first
      assert report.daily_series.all? { |_, net| net.zero? }
    end

    test "today's awards land on today" do
      PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework))

      report = ChildReport.new(@child, days: 30)
      date, net = report.daily_series.last

      assert_equal Time.zone.today, date
      assert_equal 3, net
    end

    test "reverted events are ignored" do
      event = PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework))
      event.revert!

      assert ChildReport.new(@child, days: 30).empty?
    end

    test "the breakdown groups by behaviour, biggest first" do
      3.times { PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework)) }
      PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:helping))

      report = ChildReport.new(@child, days: 30)

      assert_equal "Homework done", report.breakdown.first[:label]
      assert_equal 3, report.breakdown.first[:count]
      assert_equal 9, report.breakdown.first[:points]
    end

    test "the positive ratio is a percentage of awards, not of points" do
      3.times { PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework)) }
      PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:teasing))

      assert_equal 75, ChildReport.new(@child, days: 30).positive_ratio
    end

    test "the ratio is nil before anything has happened" do
      assert_nil ChildReport.new(@child, days: 30).positive_ratio
    end

    test "this week and last week are compared" do
      PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework),
                        occurred_at: Time.zone.today.beginning_of_week(:monday).noon)
      PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:helping),
                        occurred_at: (Time.zone.today.beginning_of_week(:monday) - 7).noon)

      report = ChildReport.new(@child, days: 30)

      assert_equal 3, report.this_week_net
      assert_equal 2, report.last_week_net
      assert_equal 1, report.week_delta
    end
  end
end
