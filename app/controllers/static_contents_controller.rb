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
          version
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

    if @static_content.name == "not found" && @static_content.content == ""
      redirect_to static_contents_path
    end
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @static_content = new_static_content_record(params.fetch(:static_content))
      render :new
      return
    end

    new_name = results.data.create_or_update_static_content.name
    new_version = results.data.create_or_update_static_content.version
    flash[:notice] = "Statischer Inhalt wurde erstellt"
    redirect_to edit_static_content_path(new_name, version: new_version)
  end

  def update
    static_content_name = params[:name]
    static_content_version = params[:static_content][:version]
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
    redirect_to edit_static_content_path(static_content_name, version: static_content_version)
  end

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

    def new_static_content_record(params = nil)
      OpenStruct.new(params)
    end

    def edit_static_content_record
      results = @smart_village.query <<~GRAPHQL
        query {
          staticContent: publicHtmlFile(
            name: "#{params[:name]}",
            version: "#{params[:version]}"
          ) {
            id
            name
            content
            version
            updatedAt
            createdAt
          }
        }
      GRAPHQL

      results.data.static_content
    end

    def create_params
      @static_content_params = params.require(:static_content).permit!
      Converter::Base.new.build_mutation(
        "createOrUpdateStaticContent",
        @static_content_params,
        false,
        "id name version"
      )
    end
end
