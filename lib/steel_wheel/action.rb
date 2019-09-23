module SteelWheel
  class Action < SimpleDelegator
    alias given __getobj__
  end
end
