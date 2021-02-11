# frozen_string_literal: true

class Importer::WasteCalendar
  attr_accessor :smart_village, :waste_types, :address_data, :tour_data,
                :address_assignment, :tour_assignment

  # address_assignment = {"street"=>"STRASSE", "zip"=>"PLZ", "city"=>"ORT", "paper"=>"PAP",
  #   "recyclable"=>"LVP", "residual"=>"HM", "bio"=>"Bio", "glas_white"=>"", "glas_color"=>""}
  #
  # tour_assignment = {"date"=>"Datum", "paper"=>"PPK", "recyclable"=>"LVP", "residual"=>"HM",
  #   "bio"=>"BIO", "glas_white"=>"", "glas_color"=>""}

  def initialize(smart_village:, waste_types:, address_data:, tour_data:, address_assignment:, tour_assignment:)
    @smart_village = smart_village
    @waste_types = waste_types
    @address_data = address_data
    @tour_data = tour_data
    @address_assignment = address_assignment
    @tour_assignment = tour_assignment
  end

  def perform
    @tour_data.each do |tour_data_line|
      @waste_types.each do |waste_type_key, _waste_type|
        next if @tour_assignment[waste_type_key].blank?
        next if @address_assignment[waste_type_key].blank?

        date = tour_data_line.fetch(@tour_assignment["date"], "")
        next if date.blank?

        tour_connection_id = tour_data_line[@tour_assignment[waste_type_key]]
        @address_data.each do |address_data_line|
          address_connection_id = address_data_line[@address_assignment[waste_type_key]]
          next if tour_connection_id != address_connection_id

          street = address_data_line.fetch(@address_assignment["street"], "")
          zip = address_data_line.fetch(@address_assignment["zip"], "")
          city = address_data_line.fetch(@address_assignment["city"], "")
          next if street.blank? || zip.blank? || city.blank?

          send_single_pick_up_time(date, waste_type_key, street, zip, city)
        end
      end
    end
  end

  def send_single_pick_up_time(date, waste_type, street, zip, city)
    results = @smart_village.query <<~GRAPHQL
      mutation {
        createWastePickUpTime (
          pickupDate: "#{date}",
          wasteLocationType: {
            wasteType: "#{waste_type}",
            address: {street: "#{street}", zip: "#{zip}", city: "#{city}"}}
        ) { id }
      }
    GRAPHQL
    results.data
  end
end
