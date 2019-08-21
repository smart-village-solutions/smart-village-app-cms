module ApplicationHelper
  def visible_in_role?(role_name)
    @current_user.roles.fetch(role_name, false) == true
  end
end
