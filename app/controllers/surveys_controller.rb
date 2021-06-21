# frozen_string_literal: true

class SurveysController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        surveys {
          id
          title
          questionTitle
          visible
          dataProvider {
            name
          }
          updatedAt
          createdAt
        }
      }
    GRAPHQL

    @surveys = results.data.surveys
  end

  def new
    @survey = new_survey_record
  end

  def edit
    # TODO: request data for edit form
    flash[:notice] = "Umfragen können noch nicht bearbeitet werden"
    redirect_to surveys_path
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @survey = new_survey_record
      render :new
      return
    end
    new_id = results.data.create_survey_poll.id
    flash[:notice] = "Umfrage wurde erstellt"
    redirect_to edit_survey_path(new_id)
  end

  def destroy
    results = @smart_village.query <<~GRAPHQL
      mutation {
        destroyRecord(
          id: #{params["id"]},
          recordType: "Survey::Poll"
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
    redirect_to surveys_path
  end

  private

    def new_survey_record
      OpenStruct.new(
        date: OpenStruct.new,
        response_options: Array.new(10, OpenStruct.new)
      )
    end

    def create_params
      @survey_params = params.require(:survey).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createSurveyPoll", @survey_params)
    end

    def convert_params_for_graphql
      # Convert date, as we always have and need exactly one
      if @survey_params["dates"].present?
        dates = @survey_params.delete(:dates)
        @survey_params["date"] = dates["0"]
      end

      # Convert has_many response_options
      if @survey_params["response_options"].present?
        response_options = []
        @survey_params["response_options"].each do |_key, response_option|
          next if response_option.blank?
          next unless nested_values?(response_option.to_h).include?(true)

          response_options << response_option
        end
        @survey_params["response_options"] = response_options
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
