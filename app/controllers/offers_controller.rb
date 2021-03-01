# frozen_string_literal: true

class OffersController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Offer") {
          id
          title
          createdAt
          payload
        }
      }
    GRAPHQL

    @offers = results.data.generic_items
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
          genericType
          title
          createdAt
          payload
        }
      }
    GRAPHQL

    @offer = results.data.generic_item
  end

  def show
  end

  def create
    query = create_params
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
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_offer_path(old_id)
      return
    end

    new_id = results.data.create_generic_item.id

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(
            id: #{old_id},
            recordType: "GenericItem"
          ) {
            id
            status
            statusCode
          }
        }
      GRAPHQL

      redirect_to edit_offer_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_offer_path(old_id)
    end
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

    def new_generic_item
      OpenStruct.new(
        generic_type: "Offer",
        addresses: [OpenStruct.new],
        dates: [OpenStruct.new],
        price_informations: [OpenStruct.new],
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
      )
    end

    def create_params
      @offer_params = params.require(:offer).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createGenericItem", @offer_params)
    end

    def convert_params_for_graphql
      # Convert has_many price_informations
      if @offer_params["price_informations"].present?
        price_informations = []
        @offer_params["price_informations"].each do |_key, price_information|
          next if price_information.blank?

          price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present?
          price_information["age_from"] = price_information["age_from"].present? ? price_information["age_from"].to_f : nil
          price_information["age_to"] = price_information["age_to"].present? ? price_information["age_to"].to_f : nil
          price_informations << price_information
        end
        @offer_params["price_informations"] = price_informations
      end

      # Convert has_many media_contents
      if @offer_params["media_contents"].present?
        media_contents = []
        @offer_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?

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

          dates << date
        end
        @offer_params["dates"] = dates
      end
    end

    # check for present values recursively
    def nested_values?(value_to_check, result = [])
      result << true if value_to_check.class == String && value_to_check.present?

      if value_to_check.class == Array
        value_to_check.each do |value|
          nested_values?(value, result)
        end
      elsif value_to_check.class.to_s.include?("Hash")
        value_to_check.each do |_key, value|
          nested_values?(value, result)
        end
      end

      result
    end
end
