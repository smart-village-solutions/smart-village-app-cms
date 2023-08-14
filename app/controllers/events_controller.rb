# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_event_record") }
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new, :create]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        eventRecords {
          id
          title
          categories {
            name
          }
          visible
          dataProvider {
            name
          }
          dates {
            dateStart
            dateEnd
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @events = results.data.event_records
  end

  def show
  end

  def new
    @event = new_event_record
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        eventRecord(
          id: #{params[:id]}
        ) {
          id
          title
          categories {
            id
            name
          }
          parentId
          region {
            name
          }
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
          contacts {
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
          dates {
            id
            weekday
            dateStart
            dateEnd
            timeStart
            timeEnd
            timeDescription
            useOnlyTimeDescription
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
          organizer {
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
          repeat
          repeatDuration {
            everyYear
            startDate
            endDate
          }
          urls {
            id
            url
            description
          }
          dataProvider {
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
              geoLocation {
                latitude
                longitude
              }
            }
            logo {
              url
              description
            }
          }
          tagList
          accessibilityInformation {
            description
            types
            urls {
              url
              description
            }
          }
        }
      }
    GRAPHQL

    @event = results.data.event_record
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to events_path
  end

  def create
    query = create_or_update_mutation
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @event = new_event_record
      render :new
      return
    end
    new_id = results.data.create_event_record.id
    flash[:notice] = "Veranstaltung wurde erstellt"
    redirect_to edit_event_path(new_id)
  end

  def update
    return copy if is_a_copy?

    event_id = params[:id]
    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_event_path(event_id)
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "EventRecord"
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
    redirect_to events_path
  end

  def copy
    query = create_or_update_mutation(false, true)

    begin
      results = @smart_village.query query
      new_event_id = results.data.create_event_record.id 

      # die Sichtbarkeit wird auf unsichtbar
      @smart_village.query <<~GRAPHQL
        mutation {
          changeVisibility (
            id: #{new_event_id},
            recordType: "EventRecord",
            visible: false
          ) {
            id
            status
            statusCode
          }
        }
      GRAPHQL
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @event = new_event_record
      render :edit
      return
    end

    flash[:notice] = "Veranstaltung wurde kopiert"
    redirect_to "/events"
  end

  private

    def event_params
      params.require(:event).permit!
    end

    def new_event_record
      OpenStruct.new(
        addresses: [OpenStruct.new],
        dates: [OpenStruct.new],
        contacts: [OpenStruct.new],
        price_informations: [OpenStruct.new],
        repeat_duration: OpenStruct.new,
        urls: [OpenStruct.new],
        organizer: OpenStruct.new(
          web_urls: [OpenStruct.new],
          contact: OpenStruct.new,
          address: OpenStruct.new
        ),
        media_contents: [OpenStruct.new]
      )
    end

    def create_or_update_mutation(update = false, is_copy = false)
      @event_params = event_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createEventRecord", @event_params, update, is_copy)
    end

    def convert_params_for_graphql
      # Convert has_many categories
      if @event_params["categories"].present?
        categories = []
        @event_params["categories"].each do |_key, category|
          next if category.blank?
          next unless nested_values?(category.to_h).include?(true)

          categories << category
        end
        @event_params["categories"] = categories
      end

      # Convert has_many addresses
      if @event_params["addresses"].present?
        addresses = []
        @event_params["addresses"].each do |_key, address|
          next if address.blank?
          next unless nested_values?(address.to_h).include?(true)

          addresses << address
        end
        @event_params["addresses"] = addresses
      end

      # Convert has_many price_informations
      if @event_params["price_informations"].present?
        price_informations = []
        @event_params["price_informations"].each do |_key, price_information|
          next if price_information.blank?
          next unless nested_values?(price_information.to_h).include?(true)

          price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present? || price_information["description"].present?
          price_information["age_from"] = price_information["age_from"].present? ? price_information["age_from"].to_f : nil
          price_information["age_to"] = price_information["age_to"].present? ? price_information["age_to"].to_f : nil
          price_informations << price_information
        end
        @event_params["price_informations"] = price_informations
      end

      # Convert has_many contacts
      if @event_params["contacts"].present?
        contacts = []
        @event_params["contacts"].each do |_key, contact|
          next if contact.blank?
          next unless nested_values?(contact.to_h).include?(true)

          contacts << contact
        end
        @event_params["contacts"] = contacts
      end

      # Convert has_many media_contents
      if @event_params["media_contents"].present?
        media_contents = []
        @event_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?
          # content_type is always something (default: `image`), so we need to check all values
          # except that to know, if the object is an empty one
          next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @event_params["media_contents"] = media_contents
      end

      # Convert has_many dates
      if @event_params["dates"].present?
        dates = []
        @event_params["dates"].each do |_key, date|
          next if date.blank?
          next unless nested_values?(date.to_h).include?(true)

          dates << date
        end
        @event_params["dates"] = dates
      end

      # Convert has_many urls
      if @event_params["urls"].present?
        urls = []
        @event_params["urls"].each do |_key, url|
          next if url.blank?

          urls << url
        end
        @event_params["urls"] = urls
      end

      # Check recursively if any organizer data is given.
      # If not, we do not want to submit the params, because the name is required by the model,
      # which will result in a validation error.
      if @event_params["organizer"].present?
        unless nested_values?(@event_params["organizer"].to_h).include?(true)
          @event_params.delete :organizer
        end
      end
    end

    def is_a_copy?
      params[:commit] == I18n.t("buttons.copy")
    end
end
