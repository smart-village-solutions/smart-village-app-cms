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
    @news_item = OpenStruct.new(
      address: OpenStruct.new(),
      source_url: OpenStruct.new,
      media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
    )
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
    query {
      newsItem(id: #{params[:id]}) {
        id
        author
        fullVersion
        charactersToBeShown
        publicationDate
        publishedAt
        title
        externalId
        sourceUrl {
          url
          description
        }
        address {
          addition
          street
          zip
          city
          geoLocation {
            latitude
            longitude
          }
        }
        dataProvider {
          name
          contact {
            firstName
            lastName
            phone
            fax
            email
            webUrls {
              url
              description
            }
          }
          address {
            addition
            street
            zip
            city
            geoLocation {
              latitude
              longitude
            }
          }
          logo {
            url
            description
          }
        }
        contentBlocks {
          title
          intro
          body
          mediaContents {
            id
            captionText
            contentType
            copyright
            height
            width
            sourceUrl {
              url
              description
            }
          }
        }
	    }
    }
    GRAPHQL

    @news_item = results.data.news_item
  end

  def create
  end

  def update
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_news_item_path(old_id)
      return
    end

    new_id = results.data.create_news_item.id
    # ToDo Check if destroy_record was succesfull
    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(id: #{old_id}, recordType: "NewsItem") {
            id
            status
            statusCode
          }
        }
      GRAPHQL

      redirect_to edit_news_item_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_news_item_path(old_id)
    end
  end

  def destroy
  end

  private

  def create_params
    @news_item_params = params.require(:news_item).permit!
    convert_params_for_graphql
    Converter::Base.new.build_mutation('createNewsItem', @news_item_params)
  end

  def convert_params_for_graphql
      # Convert has_many content_blocks(which has_many media_contents)
      content_block_params = @news_item_params["content_blocks"]
      return unless content_block_params.present?

      content_blocks = []
      media_contents = []
      content_block_params.each do |key, content_block|
        next if content_block.blank?
        content_block[:media_contents].each do |key, media_content|
          media_contents << media_content
        end
        content_block[:media_contents] = media_contents
        content_blocks << content_block
      end
      @news_item_params["content_blocks"] = content_blocks
  end
end
