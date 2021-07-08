# frozen_string_literal: true

class JobsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Job") {
          id
          title
          payload
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @jobs = results.data.generic_items
  end

  def show
  end

  def new
    @job = new_generic_item
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
          publicationDate
          payload
          contacts {
            id
            email
            fax
            lastName
            firstName
            phone
            webUrls {
              url
              description
            }
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

    @job = results.data.generic_item
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @job = new_generic_item
      render :new
      return
    end
    new_id = results.data.create_generic_item.id
    flash[:notice] = "Stellenanzeige wurde erstellt"
    redirect_to edit_job_path(new_id)
  end

  def update
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_job_path(old_id)
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

      redirect_to edit_job_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_job_path(old_id)
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
    redirect_to jobs_path
  end

  private

    def new_generic_item
      OpenStruct.new(
        generic_type: "Job",
        contacts: [OpenStruct.new(web_urls: [OpenStruct.new])],
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

    def create_params
      @job_params = params.require(:job).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createGenericItem", @job_params)
    end

    def convert_params_for_graphql
      # Convert has_many contacts
      if @job_params["contacts"].present?
        contacts = []
        @job_params["contacts"].each do |_key, contact|
          next if contact.blank?
          next unless nested_values?(contact.to_h).include?(true)

          contacts << contact
        end
        @job_params["contacts"] = contacts
      end

      # Convert has_many content_blocks(which has_many media_contents)
      content_block_params = @job_params["content_blocks"]
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
      @job_params["content_blocks"] = content_blocks

      # Convert has_many media_contents
      if @job_params["media_contents"].present?
        media_contents = []
        @job_params["media_contents"].each do |_key, media_content|
          next if media_content.blank?
          # content_type is always something (default: `image`), so we need to check all values
          # except that to know, if the object is an empty one
          next unless nested_values?(media_content.except(:content_type).to_h).include?(true)

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @job_params["media_contents"] = media_contents
      end

      # Convert has_many dates
      if @job_params["dates"].present?
        dates = []
        @job_params["dates"].each do |_key, date|
          next if date.blank?
          next unless nested_values?(date.to_h).include?(true)

          dates << date
        end
        @job_params["dates"] = dates
      end

      # Check if `operating_company` data is given.
      # For jobs we need an array as `companies`, so we need to remove `operating_company` data
      # and create an array of its data as companies.
      if @job_params["operating_company"].present?
        if nested_values?(@job_params["operating_company"].to_h).include?(true)
          @job_params["companies"] = [@job_params["operating_company"]]
        end
        @job_params.delete :operating_company
      end
    end
end
