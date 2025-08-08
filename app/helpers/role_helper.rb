module RoleHelper
  def manager?
    return false unless current_user

    current_user.admin? || current_user.supervisor?
  end

  def admin_role?
    current_user&.admin?
  end

  def supervisor_role?
    current_user&.supervisor?
  end
end
