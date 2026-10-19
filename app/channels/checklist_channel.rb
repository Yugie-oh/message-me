class ChecklistChannel < ApplicationCable::Channel
  def subscribed
    checklist = Checklist.find_by(id: params[:checklist_id])
    reject unless checklist && current_user && checklist.member?(current_user)

    stream_for checklist
  end

  def unsubscribed
    return unless current_user && params[:checklist_id]

    Item.where(checklist_id: params[:checklist_id], editing_by_id: current_user.id).find_each do |item|
      item.release_lock!
      ChecklistBroadcaster.item_updated(item)
    end
  end
end
