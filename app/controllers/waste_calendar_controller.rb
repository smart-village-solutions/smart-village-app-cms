# frozen_string_literal: true

require "csv"

class WasteCalendarController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :determine_waste_types, only: %i[index new edit_tour edit_location tour_dates]
  before_action :determine_waste_locations, only: %i[new edit_tour edit_location]
  before_action :determine_tour_list, only: %i[new edit_tour edit_location tour_dates update_tour_dates]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        publicJsonFile(name: "wasteTypes", version: "1.0.0") {
          content
        }
      }
    GRAPHQL

    @waste_types = results.data.public_json_file.content

    results = @smart_village.query <<~GRAPHQL
      query {
        wasteAddresses(limit: 100) {
          id
          street
          city
          zip
          wasteLocationTypes {
            wasteType
            id
            listPickUpDates
          }
        }
      }
    GRAPHQL

    @waste_locations = results.data.waste_addresses
  end

  def import
  end

  def new
  end

  def create_street_tour_matrix
    location_tour_matrix = params[:location_tour]
    location_tour_matrix.each do |address_id, tour_ids|
      tour_ids.each do |tour_id, tour_value|
        waste_tour_matrix = { tour_id: tour_id, tour_value: tour_value == "true", address_id: address_id.to_i }
        query = Converter::Base.new.build_mutation("assignWasteLocationToTour", waste_tour_matrix, false)
        @smart_village.query query
      end
    end
    redirect_to action: :new
  end

  def create_tour_pickup_times
  end

  def create_location
    query = Converter::Base.new.build_mutation("createWasteLocation", waste_location_params, waste_location_params.include?(:id))
    results = @smart_village.query query

    redirect_to action: :new
  end

  def edit_location
    @edit_location_id = params[:location_id]
    results = @smart_village.query <<~GRAPHQL
      query {
        wasteAddresses(ids: [#{@edit_location_id}] ) {
          id
          street
          city
          zip
        }
      }
    GRAPHQL

    @location = results.data.waste_addresses.first
    render action: :new
  end

  def remove_location
    @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "Address"
        ) {
          id
          status
          statusCode
        }
      }
    GRAPHQL
    redirect_to action: :new
  end

  def create_tour
    query = Converter::Base.new.build_mutation("createWasteTour", waste_tour_params, waste_tour_params.include?(:id))
    results = @smart_village.query query
    redirect_to action: :new
  end

  def edit_tour
    @edit_tour_id = params[:tour_id]
    render action: :new
  end

  def tour_dates
    @edit_year = (params[:year].presence || Date.today.year).to_i
    @beginning_of_year = Date.strptime(@edit_year.to_s, "%Y").beginning_of_year
    @end_of_year = Date.strptime(@edit_year.to_s, "%Y").end_of_year

    @calendar_weeks = calendarweeks_of_year(@edit_year)

    tour_id = params[:id]
    @tour = @waste_tours.select { |tour| tour.id == tour_id }.first

    results = @smart_village.query <<~GRAPHQL
      query {
        wasteTourDates(tourId: #{tour_id}) {
          id
          pickupDate
        }
      }
    GRAPHQL
    @pickup_dates = results.data.waste_tour_dates.map(&:pickup_date).flatten.compact
  end

  def update_tour_dates
    tour_id = params[:id]
    edit_year = params[:year]
    tour_dates = tour_date_params.select { |_key, value| value == "true" }

    @smart_village.query <<~GRAPHQL
      mutation {
        updateWasteTourDates(
          id: #{tour_id},
          year: "#{edit_year}",
          dates: #{tour_dates.keys}
        ) {
          id
        }
      }
    GRAPHQL

    redirect_to action: :tour_dates, id: tour_id, year: edit_year
  end

  def remove_tour
    @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "Waste::Tour"
        ) {
          id
          status
          statusCode
        }
      }
    GRAPHQL
    redirect_to action: :new
  end

  # Import CSV Data
  def create
    results = @smart_village.query <<~GRAPHQL
      query {
        publicJsonFile(name: "wasteTypes", version: "1.0.0") {
          content
        }
      }
    GRAPHQL

    @waste_types = results.data.public_json_file.content

    @address_data = params[:address_data]
    @tour_data = params[:tour_data]

    # determine separators
    col_separator_address = @address_data.include?(";") ? ";" : ","
    col_separator_tour = @tour_data.include?(";") ? ";" : ","

    parsed_address_data = CSV.parse(@address_data, headers: true, col_sep: col_separator_address)
    parsed_tour_data = CSV.parse(@tour_data, headers: true, col_sep: col_separator_tour)

    unless parsed_address_data.present? && parsed_tour_data.present?
      flash[:notice] = "Bitte Adress- und Tourdaten eintragen"
      redirect_to action: :new and return
    end

    @address_data_selects = parsed_address_data.first.headers
    @tour_data_selects = parsed_tour_data.first.headers

    address_assignment = params[:address]
    tour_assignment = params[:tour]

    # address and tour params are necessary for step 2, so without them this method is done here
    return unless address_assignment.present? && tour_assignment.present?

    unless value_present(address_assignment) && value_present(tour_assignment)
      flash[:notice] = "Bitte etwas bei Adress- und Tourdaten zuordnen für den Import"
      return
    end

    Thread.new do
      waste_importer = Importer::WasteCalendar.new(
        smart_village: @smart_village,
        waste_types: @waste_types,
        address_data: parsed_address_data,
        address_assignment: address_assignment,
        tour_data: parsed_tour_data,
        tour_assignment: tour_assignment
      )
      waste_importer.perform
    end

    flash[:notice] = "Import im Hintergrund gestartet ..."
    redirect_to action: :index
  end

  private

    def calendarweeks_of_year(year)
      last_day = Date.new(year).end_of_year
      if last_day.cweek == 1
        last_day.prev_week.cweek
      else
        last_day.cweek
      end
    end

    def determine_tour_list
      tour_query = @smart_village.query <<~GRAPHQL
        query {
          wasteTours {
            id
            title
            wasteType
          }
        }
      GRAPHQL
      @waste_tours = tour_query.data.waste_tours
    end

    def determine_waste_types
      results = @smart_village.query <<~GRAPHQL
        query {
          publicJsonFile(name: "wasteTypes", version: "1.0.0") {
            content
          }
        }
      GRAPHQL

      @waste_types = results.data.public_json_file.content
    end

    def determine_waste_locations
      location_query = @smart_village.query <<~GRAPHQL
        query {
          wasteAddresses(order: street_ASC) {
            id
            street
            city
            zip
            wasteLocationTypes {
              wasteType
              id
              listPickUpDates
              wasteTour {
                id
                title
                wasteType
              }
            }
          }
        }
      GRAPHQL
      @waste_locations = location_query.data.waste_addresses
    end

    # return true, if there is at least one assignment made
    def value_present(params)
      params.values.filter(&:present?).any?
    end

    def waste_location_params
      params.require(:waste_location).permit!
    end

    def waste_tour_params
      params.require(:waste_tour).permit!
    end

    def tour_date_params
      params.require(:tour_dates).permit!
    end
end
