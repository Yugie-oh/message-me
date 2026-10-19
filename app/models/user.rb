class User < ApplicationRecord
  validates :username, presence: true, length: { minimum: 3, maximum: 15 },
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only use letters, numbers, and underscores" }
  validates :password, confirmation: true, length: { minimum: 6 }, allow_nil: true

  has_many :messages, dependent: :destroy
  has_many :owned_checklists, class_name: "Checklist", foreign_key: :owner_id, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :checklists, through: :memberships
  has_many :join_requests, dependent: :destroy
  has_many :items, dependent: :destroy
  has_secure_password
end
