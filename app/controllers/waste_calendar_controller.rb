# frozen_string_literal: true

require "csv"

class WasteCalendarController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        publicJsonFile(name: "wasteTypes") {
          content
        }
      }
    GRAPHQL

    @waste_types = JSON.parse(results.data.public_json_file.content)

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

  def new
  end

  def create
    results = @smart_village.query <<~GRAPHQL
      query {
        publicJsonFile(name: "wasteTypes") {
          content
        }
      }
    GRAPHQL

    @waste_types = JSON.parse(results.data.public_json_file.content)

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

    # address and tour params are necessary for step 2, so without them this method is done here
    return unless params[:address].present? && params[:tour].present?

    unless value_present(params[:address]) && value_present(params[:tour])
      flash[:notice] = "Bitte etwas bei Adress- und Tourdaten zuordnen für den Import"
      return
    end

    Thread.new do
      waste_importer = Importer::WasteCalendar.new(
        smart_village: @smart_village,
        waste_types: @waste_types,
        address_data: parsed_address_data,
        address_assignment: params[:address],
        tour_data: parsed_tour_data,
        tour_assignment: params[:tour]
      )
      waste_importer.perform
    end

    flash[:notice] = "Import im Hintergrund gestartet ..."
    redirect_to action: :index
  end

  private

    # return true, if there is at least one assignment made
    def value_present(params)
      params.values.filter(&:present?).any?
    end
end
