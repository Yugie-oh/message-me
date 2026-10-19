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

    if item.update(done: ActiveRecord::Type::Boolean.new.cast(item_params[:done]))
      ChecklistBroadcaster.item_updated(item)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    item = @checklist.items.find(params[:id])
    item_id = item.id
    item.destroy
    ChecklistBroadcaster.item_removed(@checklist, item_id)
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

  def item_params
    params.require(:item).permit(:body, :done)
  end
end
