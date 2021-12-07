# frozen_string_literal: true

class StaticContentsController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        staticContents: publicHtmlFiles {
          id
          name
          content
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @static_contents = results.data.static_contents
  end

  def new
    @static_content = new_static_content_record
  end

  def edit
    @static_content = edit_static_content_record
  end

  # TODO: when implementing edit
  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @static_content = new_static_content_record
      render :new
      return
    end
    new_id = results.data.create_or_update_static_content_poll.id
    flash[:notice] = "Statischer Inhalt wurde erstellt"
    redirect_to edit_static_content_path(new_id)
  end

  # TODO: when implementing edit
  def update
    static_content_id = params[:id]
    query = create_params
    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @static_content = edit_static_content_record
      render :edit
      return
    end
    flash[:notice] = "Statischer Inhalt wurde aktualisiert"
    redirect_to edit_static_content_path(static_content_id)
  end

  # TODO: when implementing destroy
  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "StaticContent"
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
    redirect_to static_contents_path
  end

  private

    def new_static_content_record
      OpenStruct.new
    end

    def edit_static_content_record
      results = @smart_village.query <<~GRAPHQL
        query {
          staticContent: publicHtmlFile(
            name: #{params[:name]}
          ) {
            id
            name
            content
            updatedAt
            createdAt
          }
        }
      GRAPHQL

      results.data.static_content
    end

    def create_params
      @static_content_params = params.require(:static_content).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createOrUpdateStaticContent", @static_content_params)
    end

    # TODO: when implementing edit
    def convert_params_for_graphql
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
