# frozen_string_literal: true

class OffersController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_offer") }
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Offer") {
          id
          title
          dataProvider {
            name
          }
          publicationDate
          dates {
            dateEnd
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @offers = results.data.generic_items
  end

  def show
  end

  def new
    @offer = new_generic_item
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
          externalId
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
          publicationDate
          dates {
            dateEnd
          }
          companies {
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
              kind
              geoLocation {
                latitude
                longitude
              }
            }
          }
        }
      }
    GRAPHQL

    @offer = results.data.generic_item
  rescue Graphlient::Errors::GraphQLError
    flash[:error] = "Die angeforderte Ressource ist leider nicht verfügbar"
    redirect_to offers_path
  end

  def create
    query = create_or_update_mutation
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @offer = new_generic_item
      render :new
      return
    end
    new_id = results.data.create_generic_item.id
    flash[:notice] = "Werbliche Anzeige wurde erstellt"
    redirect_to edit_offer_path(new_id)
  end

  def update
    offer_id = params[:id]

    query = create_or_update_mutation(true)
    # logger.warn(query)

    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
    end

    redirect_to edit_offer_path(offer_id)
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
    redirect_to offers_path
  end

  private

    def offer_params
      params.require(:offer).permit!
    end

    def new_generic_item
      OpenStruct.new(
        generic_type: "Offer",
        content_blocks: [OpenStruct.new],
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)],
        dates: [OpenStruct.new],
        companies: [OpenStruct.new(
          web_urls: [OpenStruct.new],
          contact: OpenStruct.new(web_urls: [OpenStruct.new]),
          address: OpenStruct.new
        )]
      )
    end

    def create_or_update_mutation(update = false)
      @offer_params = offer_params
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createGenericItem", @offer_params, update)
    end

    def convert_params_for_graphql
      # Convert has_many content_blocks(which has_many media_contents)
      content_block_params = @offer_params["content_blocks"]
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
      @offer_params["content_blocks"] = content_blocks

      # Convert has_many media_contents
      if @offer_params["media_contents"].present?
        media_contents = []
        @offer_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?
          # content_type is always something (default: `image`), so we need to check all values
          # except that to know, if the object is an empty one
          next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @offer_params["media_contents"] = media_contents
      end

      # Convert has_many dates
      if @offer_params["dates"].present?
        dates = []
        @offer_params["dates"].each do |_key, date|
          next if date.blank?
          next unless nested_values?(date.to_h).include?(true)

          dates << date
        end
        @offer_params["dates"] = dates
      end

      # Check if `operating_company` data is given.
      # For offers we need an array as `companies`, so we need to remove `operating_company` data
      # and create an array of its data as companies.
      if @offer_params["operating_company"].present?
        if nested_values?(@offer_params["operating_company"].to_h).include?(true)
          @offer_params["companies"] = [@offer_params["operating_company"]]
        end
        @offer_params.delete :operating_company
      end
    end
end
