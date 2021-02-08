# frozen_string_literal: true

class ToursController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new]

  def index
    results = @smart_village.query <<~GRAPHQL
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
