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

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "Survey::Poll"
        ) {
          id
          status
          statusCode
        }
      }
    GRAPHQL

    flash["notice"] = if results.try(:data).try(:destroy_record).try(:status_code) == 200
                        "Eintrag wurde gelöscht"
                      else
                        "Fehler: #{results.errors.inspect}"
                      end
    redirect_to surveys_path
  end
end
