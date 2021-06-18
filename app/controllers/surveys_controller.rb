# frozen_string_literal: true

class SurveysController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        surveys {
          id
          title
          questionTitle
          visible
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @surveys = results.data.surveys
  end
end
