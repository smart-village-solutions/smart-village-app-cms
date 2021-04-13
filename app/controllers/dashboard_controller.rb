# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    job_results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Job") {
          id
        }
      }
    GRAPHQL

    news_results = @smart_village.query <<~GRAPHQL
      query {
        newsItems {
          id
        }
      }
    GRAPHQL

    event_results = @smart_village.query <<~GRAPHQL
      query {
        eventRecords {
          id
        }
      }
    GRAPHQL

    offer_results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Offer") {
          id
        }
      }
    GRAPHQL

    poi_results = @smart_village.query <<~GRAPHQL
      query {
        pointsOfInterest {
          id
        }
      }
    GRAPHQL

    tour_results = @smart_village.query <<~GRAPHQL
      query {
        tours {
          id
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
