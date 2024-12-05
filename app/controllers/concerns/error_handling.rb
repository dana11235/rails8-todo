module ErrorHandling
  def respond_with_error(invalid_resource = nil)
    Rails.logger.debug(invalid_resource)
    error = {}
    if invalid_resource
      error["status"] = 422
      error["details"] = invalid_resource.errors.full_messages
    end
    render json: error, status: error["status"]
  end
end
