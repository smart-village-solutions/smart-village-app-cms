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

  def show
    results = @smart_village.query <<~GRAPHQL
    query {
      eventRecord(id: #{params[:id]}) {
        id
        title
        category {
          name
        }
        parentId
        regionId
        description
        contacts {
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
          weekday
          dateStart
          dateEnd
          timeStart
          timeEnd
          timeDescription
          useOnlyTimeDescription
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
            geoLocation {
              latitude
              longitude
            }
          }
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
      }
    }
    GRAPHQL

    @event = results.data.event_record
  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end
end
