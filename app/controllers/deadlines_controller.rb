# frozen_string_literal: true

class DeadlinesController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_deadlines") }
  before_action :init_graphql_client
  before_action :load_deadline_category_list, only: %i[edit new create]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Deadline") {
          id
          title
          dataProvider {
            name
          }
          dates {
            dateStart
            timeStart
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @deadlines = results.data.generic_items
  end

  def show
  end

  def new
    @deadline = new_generic_item
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItem(
          id: #{params[:id]}
        ){
          id
          title
          genericType
          categories {
            id
            name
          }
          contentBlocks {
            body
          }
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
          dates {
            dateStart
            timeStart
          }
          pushNotifications {
            onceAt
            mondayAt
            tuesdayAt
            wednesdayAt
            thursdayAt
            fridayAt
            saturdayAt
            sundayAt
            recurring
            title
            body
            data {
              id
              queryType
              dataProviderId
            }
          }
        }
      }
    GRAPHQL

    @deadline = results.data.generic_item
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to deadlines_path
  end

  def create
    query = create_or_update_mutation
    begin
      results = @smart_village.query query
      schedule_push_notifications_queries
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @deadline = new_generic_item
      render :new
      return
    end
    new_id = results.data.create_generic_item.id
    flash[:notice] = "Eintrag wurde erstellt"
    redirect_to edit_deadline_path(new_id)
  end

  def update
    deadline_id = params[:id]

    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
      schedule_push_notifications_queries
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_deadline_path(deadline_id)
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "GenericItem"
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
    redirect_to deadlines_path
  end

  private

    def deadline_params
      params.require(:deadline).permit!
    end

    def load_deadline_category_list
      latest = 9_999_999_999 # very high number to always match the latest version
      results = @smart_village.query <<~GRAPHQL
        query {
          publicJsonFile(name: "globalSettings", version: "#{latest}") {
            content
          }
        }
      GRAPHQL

      global_settings = results.data.public_json_file.content
      deadlines_category_id = global_settings.dig("settings", "deadlines", "categoryId")

      load_filtered_category_list(deadlines_category_id)

      @categories = @categories.try(:first).try(:children) || []
      @categories = @categories.sort_by(&:name)
    end

    def new_generic_item
      OpenStruct.new(
        generic_type: "Deadline",
        content_blocks: [OpenStruct.new],
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)],
        dates: [OpenStruct.new]
      )
    end

    def create_or_update_mutation(update = false)
      @deadline_params = deadline_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createGenericItem", @deadline_params, update)
    end

    def convert_params_for_graphql
      # Convert has_many categories
      if @deadline_params["categories"].present?
        categories = []
        @deadline_params["categories"].each do |_key, category|
          next if category.blank?

          categories << category
        end
        @deadline_params["categories"] = categories
      end

      # Convert has_many content_blocks
      content_block_params = @deadline_params["content_blocks"]
      return unless content_block_params.present?

      content_blocks = []
      content_block_params.each do |_key, content_block|
        next if content_block.blank?
        next unless nested_values?(content_block.to_h).include?(true)

        content_blocks << content_block
      end
      @deadline_params["content_blocks"] = content_blocks

      # Convert has_many media_contents
      if @deadline_params["media_contents"].present?
        media_contents = []
        @deadline_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?
          # content_type is always something (default: `image`), so we need to check all values
          # except that to know, if the object is an empty one
          next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @deadline_params["media_contents"] = media_contents
      end

      # Convert has_many dates
      if @deadline_params["dates"].present?
        dates = []
        @deadline_params["dates"].each do |_key, date|
          next if date.blank?
          next unless nested_values?(date.to_h).include?(true)

          dates << date
        end
        @deadline_params["dates"] = dates
      end

      # Take push notification params for scheduling in separate mutation
      @push_notifications = @deadline_params.delete :push_notifications
    end

    def schedule_push_notifications_queries
      if @push_notifications.present?
        @push_notifications.each do |_key, push_notification|
          next unless nested_values?(push_notification.except(:recurring).to_h).include?(true)

          push_notification["notification_pushable_type"] = "GenericItem"
          push_notification["notification_pushable_id"] = @deadline_params["id"].to_i
          push_notification["recurring"] = push_notification["recurring"].to_i

          # Cleanup depending on recurring
          if push_notification["recurring"].zero?
            push_notification.delete :monday_at
            push_notification.delete :tuesday_at
            push_notification.delete :wednesday_at
            push_notification.delete :thursday_at
            push_notification.delete :friday_at
            push_notification.delete :saturday_at
            push_notification.delete :sunday_at
          end
          push_notification.delete :once_at if push_notification["recurring"].positive?

          query = Converter::Base.new.build_mutation("schedulePushNotification", push_notification)
          @smart_village.query query
        end
      end
    end
end
