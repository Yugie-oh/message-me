class Checklist < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :join_requests, dependent: :destroy
  has_many :items, inverse_of: :checklist, dependent: :destroy

  validates :title, presence: true, length: { maximum: 80 }

  before_validation :strip_title

  def member?(user)
    return false unless user

    memberships.exists?(user_id: user.id)
  end

  def owner?(user)
    user.present? && owner_id == user.id
  end

  def progress
    list = items.to_a
    [list.count(&:done), list.size]
  end

  private

  def strip_title
    self.title = title.to_s.strip
  end
end
