class Current < ActiveSupport::CurrentAttributes
  attribute :session, :family, :child

  delegate :user, to: :session, allow_nil: true
end
