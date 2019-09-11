module ApplicationHelper
  def visible_in_role?(role_name)
    return false if @current_user.blank?
    return false if @current_user.roles.blank?

    @current_user.roles.fetch(role_name, false) == true
  end

  def toLocalDate(date)
    return "" unless date.present?

    date.to_date.in_time_zone("Berlin").strftime("%d.%m.%Y")
  end

  def toLocalDateTime(date_time)
    return "" unless date_time.present?

    date_time.to_datetime.in_time_zone("Berlin").strftime("%d.%m.%Y %H:%M Uhr")
  end
end
