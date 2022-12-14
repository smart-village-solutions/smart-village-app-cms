# frozen_string_literal: true

class DefectReportsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_defect_report") }
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "DefectReport") {
          id
          categories {
            name
            contact {
              email
            }
          }
          contentBlocks {
            title
            body
          }
          contacts {
            email
            firstName
            phone
          }
          mediaContents {
            sourceUrl {
              url
            }
          }
          addresses {
            street
            zip
            city
            geoLocation {
              latitude
              longitude
            }
          }
          dataProvider {
            name
          }
          updatedAt
          createdAt
          visible
        }
      }
    GRAPHQL

    @defect_reports = results.data.generic_items
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

    flash["notice"] = if results.try(:data).try(:destroy_record).try(:status_code) == 200
                        "Eintrag wurde gelöscht"
                      else
                        "Fehler: #{results.errors.inspect}"
                      end
    redirect_to defect_reports_path
  end
end
