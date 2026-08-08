class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :point_events, class_name: "Dojo::PointEvent", dependent: :nullify

  belongs_to :family

  enum :role, { owner: "owner", parent: "parent", kid_viewer: "kid_viewer" }, validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 60 }
  validates :password, length: { minimum: 10 }, allow_nil: true

  # Only owners and parents may award points or change settings.
  def parent_access?
    owner? || parent?
  end

  def deletable_by?(other)
    other&.owner? && other != self && !owner?
  end

  def initials
    name.to_s.split(/\s+/).filter_map { |part| part[0] }.first(2).join.upcase
  end
end
