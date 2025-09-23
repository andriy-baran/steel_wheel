# frozen_string_literal: true

class ApplicationHandler < SteelWheel::Handler
  url_params do
    string :controller
    string :action
  end
end
