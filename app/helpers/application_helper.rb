module ApplicationHelper
  def internal_bytes_label(bytes)
    number_to_human_size(bytes.to_i)
  end

  def ops_delta_class(delta)
    return "is-flat" if delta.nil? || delta.zero?

    delta.positive? ? "is-up" : "is-down"
  end

  def ops_delta_label(delta)
    return "n/a" if delta.nil?

    sign = delta.positive? ? "+" : ""
    "#{sign}#{delta}%"
  end

  def ops_bar_width(value, max)
    max = max.to_i
    return 0 if max <= 0

    ((value.to_f / max) * 100).clamp(2, 100).round
  end

  def ops_day_label(date)
    date.strftime("%a %-d")
  end
end
