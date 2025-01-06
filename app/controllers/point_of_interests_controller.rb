# frozen_string_literal: true

class PointOfInterestsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_point_of_interest") }
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new, :create]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        pointsOfInterest {
          id
          name
          categories {
            name
          }
          visible
          dataProvider{
            id
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @points_of_interest = results.data.points_of_interest
  end

  def show
    redirect_to edit_point_of_interest_path(params[:id])
  end

  def new
    @point_of_interest = new_point_of_interest
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        pointOfInterest(
          id: #{params[:id]}
        ) {
          needsUpdate
          visible
          categories {
            id
            name
          }
          id
          name
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
          openingHours {
            weekday
            timeFrom
            timeTo
            open
            dateFrom
            dateTo
            description
          }
          contact {
            id
            email
            fax
            lastName
            firstName
            phone
            webUrls {
              url
              description
            }
          }
          priceInformations {
            id
            name
            amount
            groupPrice
            ageFrom
            ageTo
            minAdultCount
            maxAdultCount
            minChildrenCount
            maxChildrenCount
            description
            category
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
          lunches {
            id
            text
            dates {
              dateStart
              dateEnd
            }
            lunchOffers {
              id
              name
              price
            }
            pointOfInterest {
              id
            }
            pointOfInterestAttributes
          }
        }
      }
    GRAPHQL

    @point_of_interest = results.data.point_of_interest
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to point_of_interests_path
  end

  def create
    query = create_or_update_mutation
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @point_of_interest = new_point_of_interest
      render :new
      return
    end
    new_id = results.data.create_point_of_interest.id
    flash[:notice] = "Ort wurde erstellt"
    redirect_to edit_point_of_interest_path(new_id)
  end

  def update
    point_of_interest_id = params[:id]

    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_point_of_interest_path(point_of_interest_id)
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "PointOfInterest"
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
    redirect_to point_of_interests_path
  end

  private

    def point_of_interest_params
      params.require(:point_of_interest).permit!
    end

    def new_point_of_interest
      OpenStruct.new(
        addresses: [OpenStruct.new(
          geo_location: OpenStruct.new
        )],
        contact: OpenStruct.new(web_urls: [OpenStruct.new]),
        price_informations: [OpenStruct.new],
        web_urls: [OpenStruct.new],
        operating_company: OpenStruct.new(
          web_urls: [OpenStruct.new],
          contact: OpenStruct.new(web_urls: [OpenStruct.new]),
          address: OpenStruct.new
        ),
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)],
        lunches: [OpenStruct.new]
      )
    end

    def create_or_update_mutation(update = false)
      @point_of_interest_params = point_of_interest_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createPointOfInterest", @point_of_interest_params, update)
    end

    def convert_params_for_graphql
      # Check recursively if any addresses data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @point_of_interest_params["addresses"].present?
        unless nested_values?(@point_of_interest_params["addresses"].to_h).include?(true)
          @point_of_interest_params.delete :addresses
        end
      end

      # Convert has_many opening_hours
      if @point_of_interest_params["opening_hours"].present?
        opening_hours = []
        @point_of_interest_params["opening_hours"].each do |_key, opening_hour|
          next if opening_hour.blank?

          # it is needed to cast "false" to boolean here in order to pass GraphQL server validations
          # => Graphlient::Errors::ClientError (Argument 'open' on InputObject 'OpeningHourInput' has an invalid value. Expected type 'Boolean'.)
          # somehow magic happens for check_box value "true" and it is not needed
          if opening_hour[:open].present? && opening_hour[:open] == "false"
            opening_hour[:open] = false
          end
          # exclude :open from the check, because it is always something
          opening_hours << opening_hour if nested_values?(opening_hour.except(:open).to_h).include?(true)
        end
        @point_of_interest_params["opening_hours"] = opening_hours
      end

      # Convert has_many categories
      if @point_of_interest_params["categories"].present?
        categories = []
        @point_of_interest_params["categories"].each do |_key, category|
          next if category.blank?

          categories << category
        end
        @point_of_interest_params["categories"] = categories
      end

      # Convert has_many price_informations
      if @point_of_interest_params["price_informations"].present?
        price_informations = []
        @point_of_interest_params["price_informations"].each do |_key, price_information|
          next if price_information.blank?
          next unless nested_values?(price_information.to_h).include?(true)

          price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present?
          price_informations << price_information if price_information.values.filter(&:present?).any?
        end
        @point_of_interest_params["price_informations"] = price_informations
      end

      # Convert has_many media_contents
      if @point_of_interest_params["media_contents"].present?
        media_contents = []
        @point_of_interest_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?

          media_contents << media_content if media_content.dig("source_url", "url").present?
        end
        @point_of_interest_params["media_contents"] = media_contents
      end

      # Convert has_many urls
      if @point_of_interest_params["web_urls"].present?
        web_urls = []
        @point_of_interest_params["web_urls"].each do |_key, url|
          next if url.blank?

          web_urls << url
        end
        @point_of_interest_params["web_urls"] = web_urls
      end

      # Check recursively if any contact data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @point_of_interest_params["contact"].present?
        unless nested_values?(@point_of_interest_params["contact"].to_h).include?(true)
          @point_of_interest_params.delete :contact
        end
      end

      # Check recursively if any operating_company data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @point_of_interest_params["operating_company"].present?
        unless nested_values?(@point_of_interest_params["operating_company"].to_h).include?(true)
          @point_of_interest_params.delete :operating_company
        end
      end

      # Convert has_many lunches(which has_many dates and has_many lunch_offers)
      lunches_params = @point_of_interest_params["lunches"]
      return unless lunches_params.present?

      lunches = []
      lunches_params.each do |_key, lunch|
        next if lunch.blank?

        dates = []
        if lunch[:dates].present?
          lunch[:dates].each do |_key, date|
            dates << date
          end
          lunch[:dates] = dates
        end

        lunch_offers = []
        if lunch[:lunch_offers].present?
          lunch[:lunch_offers].each do |_key, lunch_offer|
            lunch_offers << lunch_offer if lunch_offer.values.filter(&:present?).any?
          end
          lunch[:lunch_offers] = lunch_offers
        end

        # Check recursively if any lunch data is given.
        # If not, we do not want to submit the params, because it would result in empty objects for
        # the app.
        if nested_values?(lunch.to_h).include?(true)
          # Convert point_of_interest_attributes
          # name and address data should be shown always in the mobile app
          point_of_interest_attributes = ["name", "addresses"]
          if lunch[:point_of_interest_attributes].present?
            if lunch[:point_of_interest_attributes][:contact].present?
              lunch[:point_of_interest_attributes][:contact].each do |key, value|
                next unless value.present? && value == "true"

                point_of_interest_attributes << "contact.#{key.camelcase(:lower)}"
                # web urls can be in contact.webUrls and in webUrls, so we need two keys in that case
                point_of_interest_attributes << key.camelcase(:lower) if key == "web_urls"
              end
            end
          end

          lunch[:point_of_interest_attributes] = point_of_interest_attributes.join(",")
          lunches << lunch
        end
      end
      @point_of_interest_params["lunches"] = lunches
    end
end
