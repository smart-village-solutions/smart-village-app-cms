class EventsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
    query {
      eventRecords {
        id
        title
        updatedAt
        createdAt
      }
    }
    GRAPHQL

    @events = results.data.event_records
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
    query {
      eventRecord(id: #{params[:id]}) {
        id
        title
        category {
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
          webUrls{
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
  end

  def new
    @event = OpenStruct.new(
      addresses: [OpenStruct.new],
      dates: [OpenStruct.new],
      contacts: [OpenStruct.new(web_urls: [OpenStruct.new])],
      price_informations: [OpenStruct.new],
      repeat_duration: OpenStruct.new,
      urls: [OpenStruct.new],
      organizer: OpenStruct.new(
        web_urls: [OpenStruct.new],
        contact: OpenStruct.new(web_urls: [OpenStruct.new]),
        address: OpenStruct.new()
      ),
      media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
    )
  end

  def show

  end

  def create
    logger.warn("*"*100)
    logger.warn(create_params)
    results = @smart_village.query create_params
    new_id = results.data.create_event_record.id
    redirect_to edit_event_path(new_id)
  end

  def update
    old_id = params[:id]
    logger.warn("*"*100)
    logger.warn(create_params)
    results = @smart_village.query create_params
    new_id = results.data.create_event_record.id

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht
      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(id: #{old_id}, recordType: "EventRecord") {
            id
            status
            statusCode
          }
        }
      GRAPHQL
      redirect_to edit_event_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_event_path(old_id)
    end
  end

  def destroy
  end

  private

  def init_defaults
    @event
  end

  def create_params
    @event_params = params.require(:event).permit!
    convert_params_for_graphql
    Converter::Base.new.build_mutation('createEventRecord', @event_params)
  end

  def convert_params_for_graphql

    # Convert has_many price_informations
    if @event_params["price_informations"].present?
      price_informations = []
      @event_params["price_informations"].each do |key, price_information|
        next if price_information.blank?
        price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present?
        price_information["age_from"] = price_information["age_from"].present? ? price_information["age_from"].to_f : nil
        price_information["age_to"] = price_information["age_to"].present? ? price_information["age_to"].to_f : nil
        price_informations << price_information
      end
      @event_params["price_informations"] = price_informations
    end

    # Convert has_many contacts
    if @event_params["contacts"].present?
      contacts = []
      @event_params["contacts"].each do |key, contact|
        next if contact.blank?
        contacts << contact
      end
      @event_params["contacts"] = contacts
    end

    # Convert has_many media_contents
    if @event_params["media_contents"].present?
      media_contents = []
      @event_params["media_contents"].each do |key, media_content|
        next if media_content.blank?
        media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
        media_contents << media_content
      end
      @event_params["media_contents"] = media_contents
    end

    # Convert has_many dates
    if @event_params["dates"].present?
      dates = []
      @event_params["dates"].each do |key, date|
        next if date.blank?
        dates << date
      end
      @event_params["dates"] = dates
    end

    # Convert has_many urls
    if @event_params["urls"].present?
      urls = []
      @event_params["urls"].each do |key, url|
        next if url.blank?
        urls << url
      end
      @event_params["urls"] = urls
    end

  end
end
