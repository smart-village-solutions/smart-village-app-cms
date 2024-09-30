# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    if helpers.visible_in_role?("role_news_item")
      news_results = @smart_village.query <<~GRAPHQL
        query {
          newsItems {
            id
          }
        }
      GRAPHQL

      @news_items = news_results.data.news_items
    end

    if helpers.visible_in_role?("role_event_record")
      event_results = @smart_village.query <<~GRAPHQL
        query {
          eventRecords {
            id
          }
        }
      GRAPHQL

      @events = event_results.data.event_records
    end

    if helpers.visible_in_role?("role_point_of_interest")
      poi_results = @smart_village.query <<~GRAPHQL
        query {
          pointsOfInterest {
            id
          }
        }
      GRAPHQL

      @points_of_interest = poi_results.data.points_of_interest
    end

    if helpers.visible_in_role?("role_tour")
      tour_results = @smart_village.query <<~GRAPHQL
        query {
          tours {
            id
          }
        }
      GRAPHQL

      @tours = tour_results.data.tours
    end

    if helpers.visible_in_role?("role_job")
      job_results = @smart_village.query <<~GRAPHQL
        query {
          genericItems(genericType: "Job") {
            id
          }
        }
      GRAPHQL

      @jobs = job_results.data.generic_items
    end

    if helpers.visible_in_role?("role_offer")
      offer_results = @smart_village.query <<~GRAPHQL
        query {
          genericItems(genericType: "Offer") {
            id
          }
        }
      GRAPHQL

      @offers = offer_results.data.generic_items
    end

    if helpers.visible_in_role?("role_construction_site")
      construction_results = @smart_village.query <<~GRAPHQL
        query {
          genericItems(genericType: "ConstructionSite") {
            id
          }
        }
      GRAPHQL

      @constructions = construction_results.data.generic_items
    end

    if helpers.visible_in_role?("role_waste_calendar")
      waste_location_results = @smart_village.query <<~GRAPHQL
        query {
          wasteAddresses(limit: 100) {
            id
          }
        }
      GRAPHQL

      @waste_locations = waste_location_results.data.waste_addresses
    end

    if helpers.visible_in_role?("role_survey")
      survey_results = @smart_village.query <<~GRAPHQL
        query {
          surveys {
            id
          }
        }
      GRAPHQL

      @surveys = survey_results.data.surveys
    end

    if helpers.visible_in_role?("role_static_contents")
      static_content_results = @smart_village.query <<~GRAPHQL
        query {
          staticContents: publicHtmlFiles {
            id
          }
        }
      GRAPHQL

      @static_contents = static_content_results.data.static_contents
    end

    if helpers.visible_in_role?("role_deadlines")
      deadline_results = @smart_village.query <<~GRAPHQL
        query {
          genericItems(genericType: "Deadline") {
            id
          }
        }
      GRAPHQL

      @deadlines = deadline_results.data.generic_items
    end

    if helpers.visible_in_role?("role_noticeboard")
      category_results = @smart_village.query <<~GRAPHQL
        query {
          categories(tagList: "generic_item_noticeboard", order: id_ASC) {
            id
            name
            children {
              id
            }
          }
        }
      GRAPHQL

      categories = category_results.data.categories

      if categories.present?
        noticeboard_categories = categories.select { |category| category.children.present? }
      end

      if noticeboard_categories.present?
        @noticeboards = []

        noticeboard_categories.each do |category|
          category_ids = category.children.map(&:id)

          noticeboard_category_results = @smart_village.query <<~GRAPHQL
            query {
              genericItems(
                genericType: "Noticeboard",
                categoryIds: #{category_ids}
              ) {
                id
              }
            }
          GRAPHQL

          @noticeboards << {
            "category_ids": category_ids,
            "name": category.name,
            "items": noticeboard_category_results.data.generic_items
          }
        end
      else
        noticeboard_results = @smart_village.query <<~GRAPHQL
          query {
            genericItems(genericType: "Noticeboard") {
              id
            }
          }
        GRAPHQL

        @noticeboards = [
          {
            "category_ids": nil,
            "name": "Schwarzes Brett",
            "items": noticeboard_results.data.generic_items
          }
        ]
      end
    end

    if helpers.visible_in_role?("role_defect_report")
      defect_report_results = @smart_village.query <<~GRAPHQL
        query {
          genericItems(genericType: "DefectReport") {
            id
          }
        }
      GRAPHQL

      @defect_reports = defect_report_results.data.generic_items
    end
  end

end
