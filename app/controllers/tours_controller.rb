class ToursController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
    query {
      tours {
        id
        name
        visible
        updatedAt
        createdAt
      }
    }
    GRAPHQL

    @tours = results.data.tours
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
