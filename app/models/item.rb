class Item < ApplicationRecord
  belongs_to :checklist, inverse_of: :items, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 200 }

  before_validation :strip_body

  private

  def strip_body
    self.body = body.to_s.strip
  end
end
