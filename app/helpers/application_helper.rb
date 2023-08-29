module ApplicationHelper
  def visible_in_role?(role_name)
    return false if @current_user.blank?
    return false if @current_user.roles.blank?

    @current_user.roles.fetch(role_name, false) == true
  end

  def editor?
    return false if @current_user.blank?
    return false if @current_user.permission.blank?
    return true if @current_user.permission == "admin"
    return true if @current_user.permission == "editor"

    false
  end

  def to_local_date(date)
    return "" unless date.present?

    date.to_date.in_time_zone("Berlin").strftime("%d.%m.%Y")
  end

  def to_local_date_time(date_time)
    return "" unless date_time.present?

    date_time.to_datetime.in_time_zone("Berlin").strftime("%d.%m.%Y %H:%M Uhr")
  end

  def to_unix_timestamp(date)
    date.present? ? DateTime.parse(date.to_s).to_i : 0
  end

  def visibility_switch(item, item_class)
    input_switch = check_box_tag(
      "visible-#{item.id}",
      item.visible ? 'freigegeben' : 'gesperrt',
      item.visible,
      class: "custom-control-input"
    )

    label_switch = label_tag(
      "visible-#{item.id}",
      "",
      class: "custom-control-label",
      onclick: visibility_location_href(item, item_class)
    )

    content_tag("div", input_switch + label_switch, class: "custom-control custom-switch")
  end

  private

  def visibility_location_href(item, item_class)
    return "location.href = '/visibility/#{item_class}/#{item.id}/#{item.visible ? 'false' : 'true'}/#{item.survey_poll_id}';" if item_class === "Survey_Comment"

    "location.href = '/visibility/#{item_class}/#{item.id}/#{item.visible ? 'false' : 'true'}';"
  end
end
