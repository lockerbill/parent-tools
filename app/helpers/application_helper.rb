module ApplicationHelper
  # Tailwind scans source files for literal class names, so every colour variant
  # has to appear here in full. Never build these strings by interpolation.
  CHIP_CLASSES = {
    "sky"     => "bg-sky-100 text-sky-800 ring-sky-200",
    "emerald" => "bg-emerald-100 text-emerald-800 ring-emerald-200",
    "amber"   => "bg-amber-100 text-amber-900 ring-amber-200",
    "rose"    => "bg-rose-100 text-rose-800 ring-rose-200",
    "violet"  => "bg-violet-100 text-violet-800 ring-violet-200",
    "teal"    => "bg-teal-100 text-teal-800 ring-teal-200",
    "orange"  => "bg-orange-100 text-orange-900 ring-orange-200",
    "indigo"  => "bg-indigo-100 text-indigo-800 ring-indigo-200",
    "slate"   => "bg-slate-100 text-slate-800 ring-slate-200"
  }.freeze

  AVATAR_CLASSES = {
    "sky"     => "bg-sky-500",
    "emerald" => "bg-emerald-500",
    "amber"   => "bg-amber-500",
    "rose"    => "bg-rose-500",
    "violet"  => "bg-violet-500",
    "teal"    => "bg-teal-500",
    "orange"  => "bg-orange-500",
    "indigo"  => "bg-indigo-500",
    "slate"   => "bg-slate-500"
  }.freeze

  RING_CLASSES = {
    "sky"     => "ring-sky-400",
    "emerald" => "ring-emerald-400",
    "amber"   => "ring-amber-400",
    "rose"    => "ring-rose-400",
    "violet"  => "ring-violet-400",
    "teal"    => "ring-teal-400",
    "orange"  => "ring-orange-400",
    "indigo"  => "ring-indigo-400",
    "slate"   => "ring-slate-400"
  }.freeze

  def chip_classes(color)
    CHIP_CLASSES.fetch(color.to_s, CHIP_CLASSES["slate"])
  end

  def avatar_bg_classes(color)
    AVATAR_CLASSES.fetch(color.to_s, AVATAR_CLASSES["slate"])
  end

  def ring_classes(color)
    RING_CLASSES.fetch(color.to_s, RING_CLASSES["slate"])
  end

  def signed_points(points)
    points.to_i.positive? ? "+#{points}" : points.to_i.to_s
  end

  def points_text_classes(points)
    points.to_i.negative? ? "text-rose-600" : "text-emerald-600"
  end

  def page_title(title)
    content_for(:title) { title }
  end

  def friendly_time(time)
    return "" if time.blank?

    time = time.in_time_zone
    if time > 1.minute.ago
      "just now"
    elsif time.to_date == Time.zone.today
      time.strftime("%-l:%M %p").downcase
    elsif time.to_date == Time.zone.yesterday
      "yesterday #{time.strftime('%-l:%M %p').downcase}"
    elsif time > 6.days.ago
      time.strftime("%A")
    else
      time.strftime("%-d %b")
    end
  end
end
