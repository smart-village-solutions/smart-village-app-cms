# frozen_string_literal: true

class ToursController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new, :create]

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
          geometryTourData {
            latitude
            longitude
          }
          tourStops {
            id
            name
            description
            payload
            location {
              geoLocation {
                latitude
                longitude
              }
            }
          }
        }
      }
    GRAPHQL

    @tour = results.data.tour
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to tours_path
  end

  def create
    query = create_or_update_mutation
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
    tour_id = params[:id]

    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_tour_path(tour_id)
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

    def tour_params
      params.require(:tour).permit!
    end

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

    def create_or_update_mutation(update = false)
      @tour_params = tour_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createTour", @tour_params, update)
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

      # Convert has_many tour_stops
      if @tour_params["tour_stops"].present?
        tour_stops = []
        @tour_params["tour_stops"].each do |_key, tour_stop|
          next if tour_stop.blank?
          next if tour_stop["name"].blank?

          if tour_stop["payload"].present?
            if tour_stop["payload"]["downloadable_uris"].present?
              downloadable_uris = []
              tour_stop["payload"]["downloadable_uris"].each do |_key, downloadable_uri|
                next if downloadable_uri.blank?
                # id and type are always something (e.g. type: "texture"), so we need to check all
                # values except that to know, if the object is an empty one
                next unless nested_values?(downloadable_uri.except(:id, :type).to_h).include?(true)

                downloadable_uris << downloadable_uri
              end
              tour_stop["payload"]["downloadable_uris"] = downloadable_uris
            end

            # convert total size to integer
            tour_stop["payload"]["total_size"] = tour_stop["payload"]["total_size"].to_i

            # set other defaults in payload
            tour_stop["payload"]["progress"] = 0
            tour_stop["payload"]["progressSize"] = 0
            tour_stop["payload"]["size"] = 0
            tour_stop["payload"]["type_format"] = "VRX"
            tour_stop["payload"]["download_type"] = "downloadable"
            tour_stop["payload"]["local_uris"] = []
          end

          tour_stops << tour_stop
        end
        @tour_params["tour_stops"] = tour_stops
      end
    end
end
