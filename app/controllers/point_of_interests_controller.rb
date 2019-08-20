class PointOfInterestsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
    query {
      pointsOfInterest {
        id
        name
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
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(id: #{params["id"]}, recordType: "PointOfInterest") {
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
end
