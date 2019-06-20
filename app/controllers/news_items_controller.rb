class NewsItemsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
    query {
      newsItems() {
        id
        contentBlocks{
          title
        }
        updatedAt
        createdAt
      }
    }
    GRAPHQL

    @news_items = results.data.news_items
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
