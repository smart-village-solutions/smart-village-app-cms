# frozen_string_literal: true

class PushNotificationsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_push_notification") }
  before_action :init_graphql_client

  def new
    results = @smart_village.query <<~GRAPHQL
      query {
        dataProviders: newsItemsDataProviders {
          id
          name
        }
      }
    GRAPHQL

    @data_providers = results.data.data_providers
    @push_notification = new_push_notification
  end

  def create
    query = create_params
    begin
      results = @smart_village.query query
    rescue Graphlient::Errors::GraphQLError => e
      flash[:error] = e.errors.messages["data"].to_s
      @push_notification = new_push_notification
      render :new
      return
    end
    flash[:notice] = "Push-Notification wurde erstellt"
    redirect_to new_push_notification_path
  end

  private

    def new_push_notification
      OpenStruct.new(
        title: "",
        body: "",
        data: OpenStruct.new(
          data_provider_id: nil
        )
      )
    end

    def create_params
      @push_notification_params = params.require(:push_notification).permit!
      Converter::Base.new.build_mutation("sendPushNotification", @push_notification_params)
    end
end
