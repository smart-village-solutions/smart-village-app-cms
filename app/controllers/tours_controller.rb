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
            if tour_stop["payload"]["scenes"].present?
              scenes = []
              total_size_calculated_from_downloadable_uris = 0

              tour_stop["payload"]["scenes"].each do |_key, scene|
                next if scene.blank?

                if scene["downloadable_uris"].present?
                  downloadable_uris = []

                  scene["downloadable_uris"].each do |_key, downloadable_uri|
                    next if downloadable_uri.blank?

                    # skip entries with empty url but set an empty object to keep indexes in order
                    if downloadable_uri.keys.include?("uri") && downloadable_uri["uri"].blank?
                      downloadable_uris << {}
                      next
                    end

                    # converts to float
                    if downloadable_uri["min_distance"].present?
                      downloadable_uri["min_distance"] = downloadable_uri["min_distance"].to_f
                    end
                    if downloadable_uri["max_distance"].present?
                      downloadable_uri["max_distance"] = downloadable_uri["max_distance"].to_f
                    end

                    # converts to array or set default value
                    if downloadable_uri.keys.include?("position")
                      downloadable_uri["position"] = if downloadable_uri["position"].present?
                                                       JSON.parse(downloadable_uri["position"])
                                                     else
                                                       [0, 0, 0]
                                                     end
                    end
                    if downloadable_uri.keys.include?("scale")
                      downloadable_uri["scale"] = if downloadable_uri["scale"].present?
                                                    JSON.parse(downloadable_uri["scale"])
                                                  else
                                                    [1, 1, 1]
                                                  end
                    end
                    if downloadable_uri.keys.include?("rotation")
                      downloadable_uri["rotation"] = if downloadable_uri["rotation"].present?
                                                       JSON.parse(downloadable_uri["rotation"])
                                                     else
                                                       [0, 0, 0]
                                                     end
                    end

                    # converts to boolean
                    if downloadable_uri.keys.include?("is_spatial_sound")
                      downloadable_uri["is_spatial_sound"] = downloadable_uri["is_spatial_sound"].to_s == "true"
                    end

                    # set default values
                    if downloadable_uri.keys.include?("color")
                      downloadable_uri["color"] = downloadable_uri["color"].presence || "#ffffff"
                    end
                    if downloadable_uri.keys.include?("temperature")
                      downloadable_uri["temperature"] = downloadable_uri["temperature"].presence || "6500"
                    end
                    if downloadable_uri.keys.include?("intensity")
                      downloadable_uri["intensity"] = downloadable_uri["intensity"].presence || "1000"
                    end

                    # converts to integer
                    if downloadable_uri["size"].present?
                      downloadable_uri["size"] = downloadable_uri["size"].to_i
                    end
                    if downloadable_uri["temperature"].present?
                      downloadable_uri["temperature"] = downloadable_uri["temperature"].to_i
                    end
                    if downloadable_uri["intensity"].present?
                      downloadable_uri["intensity"] = downloadable_uri["intensity"].to_i
                    end

                    # calculate total size
                    if downloadable_uri["size"].present?
                      total_size_calculated_from_downloadable_uris += downloadable_uri["size"]
                    end

                    downloadable_uris << downloadable_uri
                  end

                  scene["downloadable_uris"] = downloadable_uris
                end

                scene["local_uris"] = []
                scenes << scene
              end

              tour_stop["payload"]["scenes"] = scenes
            end

            # set total size
            tour_stop["payload"]["total_size"] = total_size_calculated_from_downloadable_uris

            # set other defaults in payload
            tour_stop["payload"]["progress"] = 0
            tour_stop["payload"]["progress_size"] = 0
            tour_stop["payload"]["size"] = 0
            tour_stop["payload"]["type_format"] = "VRX"
            tour_stop["payload"]["download_type"] = "downloadable"
          end

          tour_stops << tour_stop
        end
        @tour_params["tour_stops"] = tour_stops
      end
    end
end
