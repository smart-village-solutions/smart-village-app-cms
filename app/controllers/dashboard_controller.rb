# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    job_results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Job") {
          id
          title
          payload
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    news_results = @smart_village.query <<~GRAPHQL
      query {
        newsItems {
          id
          title
          dataProvider {
            name
          }
          visible
          contentBlocks {
            title
          }
          updatedAt
          createdAt
          pushNotificationsSentAt
        }
      }
    GRAPHQL

    event_results = @smart_village.query <<~GRAPHQL
      query {
        eventRecords {
          id
          title
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

    offer_results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Offer") {
          id
          title
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    poi_results = @smart_village.query <<~GRAPHQL
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

    tour_results = @smart_village.query <<~GRAPHQL
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

    @jobs = job_results.data.generic_items

    @news_items = news_results.data.news_items

    @events = event_results.data.event_records

    @offers = offer_results.data.generic_items

    @points_of_interest = poi_results.data.points_of_interest

    @tours = tour_results.data.tours
  end

end
