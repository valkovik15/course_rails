# frozen_string_literal: true

class HomeController < ApplicationController
  include ImageTransformator

  def create
    print(params)
    send_data transform(File.open(image.tempfile), File.open(params[:answers].tempfile)), type: :json, disposition: 'attachment'
  end

  def index
  end

  private

  def image
    params[:file]
  end
end
