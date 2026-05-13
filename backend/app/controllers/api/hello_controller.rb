module Api
  class HelloController < ApplicationController
    def index
      render json: { message: "Hello from Rails API", time: Time.current }
    end
  end
end
