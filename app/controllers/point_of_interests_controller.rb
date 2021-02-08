# frozen_string_literal: true

class PointOfInterestsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        pointsOfInterest {
          id
          name
          visible
          dataProvider{
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
  end

  def create
    query = create_params
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
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_point_of_interest_path(old_id)
      return
    end

    new_id = results.data.create_point_of_interest.id

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(
            id: #{old_id},
            recordType: "PointOfInterest"
          ) {
            id
            status
            statusCode
          }
        }
      GRAPHQL

      redirect_to edit_point_of_interest_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_point_of_interest_path(old_id)
    end
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

    def new_point_of_interest
      OpenStruct.new(
        addresses: [OpenStruct.new],
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

    def create_params
      @point_of_interest_params = params.require(:point_of_interest).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createPointOfInterest", @point_of_interest_params)
    end

    def convert_params_for_graphql
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

          price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present?
          price_information["age_from"] = price_information["age_from"].present? ? price_information["age_from"].to_f : nil
          price_information["age_to"] = price_information["age_to"].present? ? price_information["age_to"].to_f : nil
          price_informations << price_information
        end
        @point_of_interest_params["price_informations"] = price_informations
      end

      # Convert has_many media_contents
      if @point_of_interest_params["media_contents"].present?
        media_contents = []
        @point_of_interest_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
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
        lunch[:dates].each do |_key, date|
          dates << date
        end
        lunch[:dates] = dates

        lunch_offers = []
        lunch[:lunch_offers].each do |_key, lunch_offer|
          lunch_offers << lunch_offer
        end
        lunch[:lunch_offers] = lunch_offers

        # Convert point_of_interest_attributes urls
        # name and address data should be shown always
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
      @point_of_interest_params["lunches"] = lunches
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
