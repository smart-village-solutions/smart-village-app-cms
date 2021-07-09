module FormHelper
  def empty?(object, fields)
    !fields.map { |field| object.try(field).present? }.include?(true)
  end
end
