class Item < ApplicationRecord
  LOCK_TTL = 5.minutes

  belongs_to :checklist, inverse_of: :items, touch: true
  belongs_to :user
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :editing_by, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: 200 }

  before_validation :strip_body

  def editable_by?(editor)
    return false unless editor
    return true unless checklist.creator_only?

    user_id == editor.id
  end

  def locked?
    editing_by_id.present? && editing_at.present? && editing_at > LOCK_TTL.ago
  end

  def locked_by?(editor)
    editor.present? && locked? && editing_by_id == editor.id
  end

  def locked_by_someone_else?(editor)
    locked? && !locked_by?(editor)
  end

  def claim_lock!(editor)
    now = Time.current
    claimed = self.class.where(id: id).where(
      "editing_by_id IS NULL OR editing_by_id = ? OR editing_at IS NULL OR editing_at < ?",
      editor.id,
      LOCK_TTL.ago
    ).update_all(editing_by_id: editor.id, editing_at: now, updated_at: now)

    reload
    claimed == 1
  end

  def release_lock!
    update_columns(editing_by_id: nil, editing_at: nil, updated_at: Time.current)
    reload
  end

  private

  def strip_body
    self.body = body.to_s.strip
  end
end
