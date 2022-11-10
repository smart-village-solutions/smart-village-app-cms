# frozen_string_literal: true

class ConstructionsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_constuction_site") }
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new, :create]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "ConstructionSite") {
          id
          title
          payload
          dataProvider {
            name
          }
          dates {
            dateStart
            dateEnd
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @constructions = results.data.generic_items
  end

  def show
  end

  def new
    @construction = new_generic_item
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
          payload
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
            dateEnd
          }
          locations {
            name
            geoLocation {
              latitude
              longitude
            }
          }
        }
      }
    GRAPHQL

    @construction = results.data.generic_item
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to constructions_path
  end

  def create
    query = create_or_update_mutation
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @construction = new_generic_item
      render :new
      return
    end
    new_id = results.data.create_generic_item.id
    flash[:notice] = "Baustelle wurde erstellt"
    redirect_to edit_construction_path(new_id)
  end

  def update
    construction_id = params[:id]

    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_construction_path(construction_id)
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

    if results.try(:data).try(:destroy_record).try(:status_code) == 200
      flash["notice"] = "Eintrag wurde gelöscht"
    else
      flash["notice"] = "Fehler: #{results.errors.inspect}"
    end
    redirect_to constructions_path
  end

  private

    def construction_params
      params.require(:construction).permit!
    end

    def new_generic_item
      OpenStruct.new(
        generic_type: "ConstructionSite",
        content_blocks: [OpenStruct.new],
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)],
        dates: [OpenStruct.new]
      )
    end

    def create_or_update_mutation(update = false)
      @construction_params = construction_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createGenericItem", @construction_params, update)
    end

    def convert_params_for_graphql
      # Convert has_many categories
      if @construction_params["categories"].present?
        categories = []
        @construction_params["categories"].each do |_key, category|
          next if category.blank?

          categories << category
        end
        @construction_params["categories"] = categories
      end

      # Convert has_many content_blocks(which has_many media_contents)
      content_block_params = @construction_params["content_blocks"]
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
      @construction_params["content_blocks"] = content_blocks

      # Convert has_many media_contents
      if @construction_params["media_contents"].present?
        media_contents = []
        @construction_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?
          # content_type is always something (default: `image`), so we need to check all values
          # except that to know, if the object is an empty one
          next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @construction_params["media_contents"] = media_contents
      end

      # Convert has_many restrictions
      if @construction_params["payload"]["restrictions"].present?
        restrictions = []
        @construction_params["payload"]["restrictions"].each do |_key, value|
          next if value.blank?
          next if value["description"].blank?

          restrictions << value
        end
        @construction_params["payload"]["restrictions"] = restrictions
      end

      # Convert string to float for location options
      if @construction_params["locations"].present?
        geo_locations = []
        @construction_params["locations"].each do |_key, location|
          next if location.blank?
          next if location["geo_location"].blank?

          location["geoLocation"] = {}
          location["geoLocation"]["latitude"] = location["geo_location"]["latitude"].to_f if location["geo_location"]["latitude"].present?
          location["geoLocation"]["longitude"] = location["geo_location"]["longitude"].to_f if location["geo_location"]["longitude"].present?
          geo_locations << location
        end
        @construction_params["locations"] = geo_locations
      end

      # Convert has_many dates
      if @construction_params["dates"].present?
        dates = []
        @construction_params["dates"].each do |_key, date|
          next if date.blank?
          next unless nested_values?(date.to_h).include?(true)

          dates << date
        end
        @construction_params["dates"] = dates
      end
    end
end
