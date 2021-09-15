# frozen_string_literal: true

class NewsItemsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new, :create]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        newsItems {
          id
          title
          dataProvider {
            name
          }
          visible
          contentBlocks {
            title
          }
          updatedAt
          createdAt
          pushNotificationsSentAt
        }
      }
    GRAPHQL

    @news_items = results.data.news_items
  end

  def show
  end

  def new
    @news_item = new_news_item
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        newsItem(
          id: #{params[:id]}
        ) {
          visible
          categories {
            id
            name
          }
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
          pushNotificationsSentAt
        }
      }
    GRAPHQL

    @news_item = results.data.news_item

    redirect_to news_items_path if @news_item.push_notifications_sent_at.present?
  end

  def create
    unless category_present?(news_item_params)
      flash[:error] = "Bitte eine Kategorie auswählen"
      redirect_to new_news_item_path and return
    end

    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @news_item = new_news_item
      render :new
      return
    end
    new_id = results.data.create_news_item.id
    flash[:notice] = "Nachricht wurde erstellt"
    redirect_to edit_news_item_path(new_id)
  end

  def update
    old_id = params[:id]

    unless category_present?(news_item_params)
      flash[:error] = "Bitte eine Kategorie auswählen"
      redirect_to edit_news_item_path(old_id) and return
    end

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

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(
            id: #{old_id},
            recordType: "NewsItem"
          ) {
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
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "NewsItem"
        ) {
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
    redirect_to news_items_path
  end

  private

    def news_item_params
      params.require(:news_item).permit!
    end

    def new_news_item
      OpenStruct.new(
        address: OpenStruct.new,
        source_url: OpenStruct.new,
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
      )
    end

    def create_params
      @news_item_params = news_item_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createNewsItem", @news_item_params)
    end

    def convert_params_for_graphql
      # Convert has_many categories
      if @news_item_params["categories"].present?
        categories = []
        @news_item_params["categories"].each do |_key, category|
          next if category.blank?
          next unless nested_values?(category.to_h).include?(true)

          categories << category
        end
        @news_item_params["categories"] = categories
      end

      # Convert has_many content_blocks(which has_many media_contents)
      content_block_params = @news_item_params["content_blocks"]
      return unless content_block_params.present?

      content_blocks = []
      content_block_params.each do |_key, content_block|
        next if content_block.blank?

        if content_block[:media_contents].present?
          media_contents = []
          content_block[:media_contents].each do |_key, media_content|
            # content_type is always something (default: `image`), so we need to check all values
            # except that to know, if the object is an empty one
            next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

            media_contents << media_content
          end
          content_block[:media_contents] = media_contents
        end

        next unless nested_values?(content_block.to_h).include?(true)

        content_blocks << content_block
      end
      @news_item_params["content_blocks"] = content_blocks

      # Convert has_one source_url
      # We receive an array of urls and need to convert them to one source_url that gets transmitted
      if @news_item_params["source_urls"].present?
        if nested_values?(@news_item_params["source_urls"].to_h).include?(true)
          @news_item_params["source_url"] = @news_item_params["source_urls"]["0"]
        end
        @news_item_params.delete :source_urls
      end
    end

    # return true, if there is at least one category selected
    def category_present?(params)
      params["categories"].each do |_key, category|
        next if category.blank?
        next unless nested_values?(category.to_h).include?(true)

        return true
      end

      false
    end
end
