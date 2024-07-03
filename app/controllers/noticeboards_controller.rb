# frozen_string_literal: true

class NoticeboardsController < ApplicationController
  before_action :verify_current_user
  before_action { verify_current_user_role("role_noticeboard") }
  before_action :init_graphql_client

  def index
    results = @smart_village.query <<~GRAPHQL
      query {
        genericItems(genericType: "Noticeboard") {
          id
          categories {
            name
          }
          contentBlocks {
            title
            body
          }
          mediaContents {
            sourceUrl {
              url
            }
          }
          contacts {
            email
            firstName
          }
          dataProvider {
            name
          }
          dates {
            dateStart
            dateEnd
          }
          updatedAt
          createdAt
          visible
          genericItemMessages {
            id
          }
        }
      }
    GRAPHQL

    @noticeboards = results.data.generic_items
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
    redirect_to noticeboards_path
  end
end
