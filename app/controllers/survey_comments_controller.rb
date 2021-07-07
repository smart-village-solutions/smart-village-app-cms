# frozen_string_literal: true

class SurveyCommentsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        comments: surveyComments(
          surveyId: #{params[:survey_id]}
        ) {
          id
          surveyPollId
          message
          createdAt
          visible
        }
      }
    GRAPHQL

    @survey_comments = results.data.comments
  end
end
