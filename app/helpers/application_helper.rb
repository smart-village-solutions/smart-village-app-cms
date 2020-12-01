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

  def toLocalDate(date)
    return "" unless date.present?

    date.to_date.in_time_zone("Berlin").strftime("%d.%m.%Y")
  end

  def toLocalDateTime(date_time)
    return "" unless date_time.present?

    date_time.to_datetime.in_time_zone("Berlin").strftime("%d.%m.%Y %H:%M Uhr")
  end

  def visibility_switch(item, item_class)
    input_switch_on = content_tag("input", "freigegeben", "type": "radio", name: "options")
    input_switch_off = content_tag("input", "gesperrt", "type": "radio", name: "options")

    link_url_true = "location.href = '/visibility/#{item_class}/#{item.id}/true';"
    switch_content_on = content_tag("label", input_switch_on, class: "btn btn-sm btn-primary #{item.visible ? 'active' : ''}", "data-item-id": item.id, onclick: link_url_true)

    link_url_false = "location.href = '/visibility/#{item_class}/#{item.id}/false';"
    switch_content_off = content_tag("label", input_switch_off, class: "btn btn-sm btn-primary #{item.visible ? '' : 'active'}", "data-item-id": item.id, onclick: link_url_false)

    content_tag("div", switch_content_on + switch_content_off, class: "btn-group btn-group-toggle", "data-toggle": "buttons")
  end
end
