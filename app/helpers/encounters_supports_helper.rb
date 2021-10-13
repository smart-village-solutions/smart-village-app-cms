module EncountersSupportsHelper
  def format_birth_date(birth_date)
    return "" unless birth_date.present?

    birth_date.to_date.strftime("%d.%m.%Y")
  end
end
