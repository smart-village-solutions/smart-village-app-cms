# frozen_string_literal: true

class ToursController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        tours {
          id
          name
          visible
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @tours = results.data.tours
  end

  def show
  end

  def new
    @tour = new_tour
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        tour(
          id: #{params[:id]}
        ) {
          visible
          categories {
            id
            name
          }
          id
          name
          lengthKm
          description
          mediaContents {
            id
            captionText
            contentType
            copyright
            height
            width
            sourceUrl {
              url
              description
            }
          }
          addresses {
            addition
            street
            zip
            city
            kind
            geoLocation {
              latitude
              longitude
            }
          }
          contact {
            id
            email
            fax
            lastName
            firstName
            phone
            webUrls{
              url
              description
            }
          }
          webUrls {
            id
            url
            description
          }
          operatingCompany {
            name
            contact {
              firstName
              lastName
              phone
              fax
              email
              webUrls {
                url
                description
              }
            }
            address {
              addition
              street
              zip
              city
              kind
              geoLocation {
                latitude
                longitude
              }
            }
          }
          dataProvider {
            name
          }
        }
      }
    GRAPHQL

    @tour = results.data.tour
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @tour = new_tour
      render :new
      return
    end
    new_id = results.data.create_tour.id
    flash[:notice] = "Tour wurde erstellt"
    redirect_to edit_tour_path(new_id)
  end

  def update
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_tour_path(old_id)
      return
    end

    new_id = results.data.create_tour.id

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(
            id: #{old_id},
            recordType: "Tour"
          ) {
            id
            status
            statusCode
          }
        }
      GRAPHQL

      redirect_to edit_tour_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_tour_path(old_id)
    end
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "Tour"
        ) {
          id
          status
          statusCode
        }
      }
    GRAPHQL

    if results.try(:data).try(:destroy_record).try(:status_code) == 200
      flash["notice"] = "Eintrag wurde gelöscht"
    else
      flash["notice"] = "Fehler: #{results.errors.inspect}"
    end
    redirect_to tours_path
  end

  private

    def new_tour
      OpenStruct.new(
        addresses: [OpenStruct.new(
          geo_location: OpenStruct.new
        )],
        contact: OpenStruct.new(web_urls: [OpenStruct.new]),
        web_urls: [OpenStruct.new],
        operating_company: OpenStruct.new(
          web_urls: [OpenStruct.new],
          contact: OpenStruct.new(web_urls: [OpenStruct.new]),
          address: OpenStruct.new
        ),
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
      )
    end

    def create_params
      @tour_params = params.require(:tour).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createTour", @tour_params)
    end

    def convert_params_for_graphql
      # Check recursively if any addresses data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @tour_params["addresses"].present?
        unless nested_values?(@tour_params["addresses"].to_h).include?(true)
          @tour_params.delete :addresses
        end
      end

      # Convert has_many categories
      if @tour_params["categories"].present?
        categories = []
        @tour_params["categories"].each do |_key, category|
          next if category.blank?

          categories << category
        end
        @tour_params["categories"] = categories
      end

      # Convert length_km to Integer
      if @tour_params["length_km"].present?
        @tour_params["length_km"] = @tour_params["length_km"].to_i
      else
        @tour_params["length_km"] = 0
      end

      # Convert has_many media_contents
      if @tour_params["media_contents"].present?
        media_contents = []
        @tour_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?

          media_contents << media_content if media_content.dig("source_url", "url").present?
        end
        @tour_params["media_contents"] = media_contents
      end

      # Convert has_many urls
      if @tour_params["web_urls"].present?
        web_urls = []
        @tour_params["web_urls"].each do |_key, url|
          next if url.blank?

          web_urls << url
        end
        @tour_params["web_urls"] = web_urls
      end

      # Check recursively if any contact data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @tour_params["contact"].present?
        unless nested_values?(@tour_params["contact"].to_h).include?(true)
          @tour_params.delete :contact
        end
      end

      # Check recursively if any operating_company data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @tour_params["operating_company"].present?
        unless nested_values?(@tour_params["operating_company"].to_h).include?(true)
          @tour_params.delete :operating_company
        end
      end
    end

    # check for present values recursively
    def nested_values?(value_to_check, result = [])
      result << true if value_to_check.class == String && value_to_check.present?

      if value_to_check.class == Array
        value_to_check.each do |value|
          nested_values?(value, result)
        end
      elsif value_to_check.class.to_s.include?("Hash")
        value_to_check.each do |_key, value|
          nested_values?(value, result)
        end
      end

      result
    end
end
