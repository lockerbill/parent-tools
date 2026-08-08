module Dojo
  # Plain reporting object. Everything is computed from the ledger, so a report
  # can never drift away from what actually happened.
  class ChildReport
    attr_reader :child, :days

    def initialize(child, days: 30)
      @child = child
      @days = days
    end

    def balance
      child.points_balance
    end

    def week_start
      child.family.week_start_day
    end

    def this_week_range
      start = Time.zone.today.beginning_of_week(week_start)
      start.all_day.begin...(start + 7).all_day.begin
    end

    def last_week_range
      start = Time.zone.today.beginning_of_week(week_start) - 7
      start.all_day.begin...(start + 7).all_day.begin
    end

    def this_week_net
      @this_week_net ||= net_in(this_week_range)
    end

    def last_week_net
      @last_week_net ||= net_in(last_week_range)
    end

    def week_delta
      this_week_net - last_week_net
    end

    def from
      (Time.zone.today - (days - 1)).all_day.begin
    end

    def to
      Time.zone.today.all_day.end
    end

    def events
      @events ||= child.point_events.active.occurred_between(from, to).includes(:behavior).to_a
    end

    # [[Date, net_points], ...] for every day in the window, including empty days.
    def daily_series
      @daily_series ||= begin
        totals = events.group_by { |event| event.occurred_at.in_time_zone.to_date }
                       .transform_values { |group| group.sum(&:points) }
        ((Time.zone.today - (days - 1))..Time.zone.today).map { |date| [ date, totals.fetch(date, 0) ] }
      end
    end

    def max_abs_daily
      @max_abs_daily ||= [ daily_series.map { |_, net| net.abs }.max.to_i, 1 ].max
    end

    def positive_total
      @positive_total ||= events.select(&:positive?).sum(&:points)
    end

    def needs_work_total
      @needs_work_total ||= events.reject(&:positive?).sum(&:points).abs
    end

    def positive_count
      @positive_count ||= events.count(&:positive?)
    end

    def needs_work_count
      @needs_work_count ||= events.count { |event| !event.positive? }
    end

    def total_count
      events.size
    end

    # Share of awards that were positive, 0..100. nil when there is nothing yet.
    def positive_ratio
      return nil if total_count.zero?

      ((positive_count.to_f / total_count) * 100).round
    end

    # [{ label:, icon:, color:, count:, points: }, ...] biggest contributor first.
    def breakdown
      @breakdown ||= events.group_by { |event| event.behavior&.name || event.label }
                           .map do |label, group|
        {
          label: label,
          icon: group.first.icon,
          color: group.first.color,
          count: group.size,
          points: group.sum(&:points)
        }
      end.sort_by { |row| [ -row[:points].abs, row[:label] ] }
    end

    def redemptions
      @redemptions ||= child.redemptions.counted.includes(:reward)
                            .where(created_at: from..to).order(created_at: :desc)
    end

    def points_spent
      @points_spent ||= redemptions.sum(&:cost)
    end

    def empty?
      events.empty?
    end

    private
      def net_in(range)
        child.point_events.active.where(occurred_at: range).sum(:points)
      end
  end
end
