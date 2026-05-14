module Api
  class HelloController < ApplicationController
    allow_unauthenticated_access

    def index
      render json: { message: "Hello from Rails API", time: Time.current }
    end
  end
end
