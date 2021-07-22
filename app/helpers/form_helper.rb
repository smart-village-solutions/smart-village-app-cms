module FormHelper
  def empty?(object, fields)
    !fields.map { |field| object.try(field).present? }.include?(true)
  end

  # a lunch is empty, if there is no text, no start date, no end date, no lunch offers and no
  # checked point of interest attributes
  def lunch_empty?(object)
    return false if object.text.present?

    if object.dates.present?
      date = object.dates.first

      return false if date.try(:date_start).present? || date.try(:date_end).present?
    end

    return false if object.lunch_offers.present? && object.lunch_offers.any?

    !["phone", "email", "fax", "web_urls"].map do |attribute|
      lunch_point_of_interest_attribute_checked?(object, attribute)
    end.include?(true)
  end

  def lunch_point_of_interest_attribute_checked?(record, attribute)
    record.point_of_interest_attributes&.include?("contact.#{attribute.camelcase(:lower)}")
  end
end
