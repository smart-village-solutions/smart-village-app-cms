class PointOfInterestsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client
  before_action :load_category_list, only: [:edit, :new]

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        pointsOfInterest {
          id
          name
          visible
          dataProvider{
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @points_of_interest = results.data.points_of_interest
  end

  def show
  end

  def new
    @point_of_interest = new_point_of_interest
  end

  def edit
    results = @smart_village.query <<~GRAPHQL
      query {
        pointOfInterest(
          id: #{params[:id]}
        ) {
          visible
          categories {
            id
            name
          }
          id
          name
          description
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
          addresses {
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
          contact {
            id
            email
            fax
            lastName
            firstName
            phone
            webUrls{
              url
              description
            }
          }
          priceInformations {
            id
            name
            amount
            groupPrice
            ageFrom
            ageTo
            minAdultCount
            maxAdultCount
            minChildrenCount
            maxChildrenCount
            description
            category
          }
          webUrls {
            id
            url
            description
          }
          operatingCompany {
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
          dataProvider {
            name
          }
        }
      }
    GRAPHQL

    @point_of_interest = results.data.point_of_interest
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @point_of_interest = new_point_of_interest
      render :new
      return
    end
    new_id = results.data.create_point_of_interest.id
    flash[:notice] = "Ort wurde erstellt"
    redirect_to edit_point_of_interest_path(new_id)
  end

  def update
    old_id = params[:id]
    query = create_params
    logger.warn(query)

    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      redirect_to edit_point_of_interest_path(old_id)
      return
    end

    new_id = results.data.create_point_of_interest.id

    if new_id.present? && new_id != old_id
      # Nach dem Erstellen des neuen Datensatzes wird der alte gelöscht

      destroy_results = @smart_village.query <<~GRAPHQL
        mutation {
          destroyRecord(
            id: #{old_id},
            recordType: "PointOfInterest"
          ) {
            id
            status
            statusCode
          }
        }
      GRAPHQL

      redirect_to edit_point_of_interest_path(new_id)
    else
      flash[:error] = "Fehler: #{results.errors.inspect}"
      redirect_to edit_point_of_interest_path(old_id)
    end
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "PointOfInterest"
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
    redirect_to point_of_interests_path
  end

  private

    def new_point_of_interest
      OpenStruct.new(
        addresses: [OpenStruct.new],
        contact: OpenStruct.new(web_urls: [OpenStruct.new]),
        price_informations: [OpenStruct.new],
        web_urls: [OpenStruct.new],
        operating_company: OpenStruct.new(
          web_urls: [OpenStruct.new],
          contact: OpenStruct.new(web_urls: [OpenStruct.new]),
          address: OpenStruct.new()
        ),
        media_contents: [OpenStruct.new(source_url: OpenStruct.new)]
      )
    end

    def create_params
      @point_of_interest_params = params.require(:point_of_interest).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createPointOfInterest", @point_of_interest_params)
    end

    def convert_params_for_graphql
      # Convert has_many categories
      if @point_of_interest_params["categories"].present?
        categories = []
        @point_of_interest_params["categories"].each do |_key, category|
          next if category.blank?

          categories << category
        end
        @point_of_interest_params["categories"] = categories
      end

      # Convert has_many price_informations
      if @point_of_interest_params["price_informations"].present?
        price_informations = []
        @point_of_interest_params["price_informations"].each do |key, price_information|
          next if price_information.blank?

          price_information["amount"] = price_information["amount"].to_f if price_information["amount"].present?
          price_information["age_from"] = price_information["age_from"].present? ? price_information["age_from"].to_f : nil
          price_information["age_to"] = price_information["age_to"].present? ? price_information["age_to"].to_f : nil
          price_informations << price_information
        end
        @point_of_interest_params["price_informations"] = price_informations
      end

      # Convert has_many media_contents
      if @point_of_interest_params["media_contents"].present?
        media_contents = []
        @point_of_interest_params["media_contents"].each do |key, media_content|
          next if media_content.blank?

          media_content["source_url"] = media_content.dig("source_url", "url").present? ? media_content["source_url"] : nil
          media_contents << media_content
        end
        @point_of_interest_params["media_contents"] = media_contents
      end

      # Convert has_many urls
      if @point_of_interest_params["web_urls"].present?
        web_urls = []
        @point_of_interest_params["web_urls"].each do |key, url|
          next if url.blank?

          web_urls << url
        end
        @point_of_interest_params["web_urls"] = web_urls
      end
    end
end
