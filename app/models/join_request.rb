class JoinRequest < ApplicationRecord
  STATUSES = %w[pending approved declined].freeze

  belongs_to :checklist
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :checklist_id }

  scope :pending, -> { where(status: "pending") }

  def pending?
    status == "pending"
  end
end
