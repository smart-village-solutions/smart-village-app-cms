# frozen_string_literal: true

class SurveysController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_survey") }
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
          date {
            dateStart
            dateEnd
          }
          updatedAt
          createdAt
          comments: surveyComments {
            id
          }
          canComment
        }
      }
    GRAPHQL

    @surveys = results.data.surveys
  end

  def show
    redirect_to edit_survey_path(params[:id])
  end

  def new
    @survey = new_survey_record
  end

  def edit
    @survey = edit_survey_record
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
    new_id = results.data.create_or_update_survey_poll.id
    flash[:notice] = "Umfrage wurde erstellt"
    redirect_to edit_survey_path(new_id)
  end

  def update
    survey_id = params[:id]
    query = create_params
    begin
      @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @survey = edit_survey_record
      render :edit
      return
    end
    flash[:notice] = "Umfrage wurde aktualisiert"
    redirect_to edit_survey_path(survey_id)
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

    def edit_survey_record
      results = @smart_village.query <<~GRAPHQL
        query {
          surveys(
            ids: [
              #{params[:id]}
            ]
          ) {
            id
            title
            description
            questionId
            questionTitle
            questionAllowMultipleResponses
            date {
              dateStart
              dateEnd
              timeStart
              timeEnd
            }
            responseOptions {
              id
              title
              votesCount
            }
            visible
            dataProvider {
              name
            }
            canComment
            isMultilingual
            updatedAt
            createdAt
          }
        }
      GRAPHQL

      survey = results.data.surveys.first

      OpenStruct.new(
        id: survey.id,
        title_de: survey.title["de"],
        title_pl: survey.title["pl"],
        description_de: survey.description["de"],
        description_pl: survey.description["pl"],
        question_id: survey.question_id,
        question_title_de: survey.question_title["de"],
        question_title_pl: survey.question_title["pl"],
        question_allow_multiple_responses: survey.question_allow_multiple_responses,
        date: survey.date,
        response_options: survey.response_options.map do |response_option|
          OpenStruct.new(
            id: response_option.id,
            title_de: response_option.title["de"],
            title_pl: response_option.title["pl"],
            votes_count: response_option.votes_count
          )
        end,
        can_comment: survey.can_comment,
        is_multilingual: survey.is_multilingual
      )
    end

    def create_params
      @survey_params = params.require(:survey).permit!
      convert_params_for_graphql
      Converter::Base.new.build_mutation("createOrUpdateSurveyPoll", @survey_params)
    end

    def convert_params_for_graphql
      # Convert date, as we always have and need exactly one
      if @survey_params["dates"].present?
        dates = @survey_params.delete(:dates)
        @survey_params["date"] = dates["0"]
      end

      # Convert to boolean
      @survey_params["can_comment"] = @survey_params["can_comment"] == "true"
      @survey_params["question_allow_multiple_responses"] = @survey_params["question_allow_multiple_responses"] == "true"
      @survey_params["is_multilingual"] = @survey_params["is_multilingual"] == "true"

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
