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
  end
end
