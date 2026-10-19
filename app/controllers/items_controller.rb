class ItemsController < ApplicationController
  before_action :require_user
  before_action :set_checklist
  before_action :require_member

  def create
    item = @checklist.items.build(item_params)
    item.user = current_user

    if item.save
      ChecklistBroadcaster.item_created(item)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def update
    item = @checklist.items.find(params[:id])

    if params[:item].key?(:body)
      save_body(item)
    else
      toggle_done(item)
    end
  end

  def destroy
    item = @checklist.items.find(params[:id])

    if item.locked_by_someone_else?(current_user)
      head :conflict
      return
    end

    item_id = item.id
    item.destroy
    ChecklistBroadcaster.item_removed(@checklist, item_id)
    head :ok
  end

  def lock
    item = @checklist.items.find(params[:id])

    unless item.editable_by?(current_user)
      head :forbidden
      return
    end

    if item.claim_lock!(current_user)
      ChecklistBroadcaster.item_updated(item)
      head :ok
    else
      head :conflict
    end
  end

  def unlock
    item = @checklist.items.find(params[:id])

    unless item.locked_by?(current_user)
      head :conflict
      return
    end

    item.release_lock!
    ChecklistBroadcaster.item_updated(item)
    head :ok
  end

  private

  def set_checklist
    @checklist = Checklist.find(params[:checklist_id])
  end

  def require_member
    return if @checklist.member?(current_user)

    head :forbidden
  end

  def toggle_done(item)
    done = ActiveRecord::Type::Boolean.new.cast(item_params[:done])

    if item.update(done: done)
      ChecklistBroadcaster.item_updated(item)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def save_body(item)
    unless item.editable_by?(current_user)
      head :forbidden
      return
    end

    unless item.locked_by?(current_user)
      head :conflict
      return
    end

    item.body = item_params[:body].to_s.strip
    if item.body_changed?
      item.done = false
      item.updated_by = current_user
    end
    item.editing_by = nil
    item.editing_at = nil

    if item.save
      ChecklistBroadcaster.item_updated(item)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def item_params
    params.require(:item).permit(:body, :done)
  end
end
