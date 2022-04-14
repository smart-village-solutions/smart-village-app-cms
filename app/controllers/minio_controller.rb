# frozen_string_literal: true

require "securerandom"

# This controller handles file uploads to minio buckets
# specifically for uploading images for e.g. POIs
class MinioController < ApplicationController

  before_action :verify_current_user
  before_action :minio_setup

  def signed_url
    bucket = @minio_config["bucket"]
    headers = {}
    options = { path_style: true }

    url = @storage.put_object_url(
      bucket,
      generate_filename,
      15.minutes.from_now.to_time.to_i,
      headers,
      options
    )

    respond_to do |format|
      format.json { render json: { signedUrl: url } }
    end
  end

  private

    # We overwrite ApplicationController here, because we do not
    # need a redirect but just a http response instead
    def verify_current_user
      head :unauthorized unless session["current_user"]
    end

    def minio_setup
      @minio_config = session["current_user"]["minio"]
      @storage = Fog::Storage.new(
        provider: "AWS",
        endpoint: @minio_config["endpoint"],
        aws_access_key_id: @minio_config["access_key_id"],
        aws_secret_access_key: @minio_config["secret_access_key"],
        region: @minio_config["region"]
      )
    end

    def generate_filename
      extension = File.extname(params[:filename])
      filename = File.basename(params[:filename], extension).gsub(" ", "-")

      "cms_uploads/#{filename}-#{SecureRandom.hex}#{extension}"
    end
end
