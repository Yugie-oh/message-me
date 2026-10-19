class ChecklistChannel < ApplicationCable::Channel
  def subscribed
    checklist = Checklist.find_by(id: params[:checklist_id])
    reject unless checklist && current_user && checklist.member?(current_user)

    stream_for checklist
  end

  def unsubscribed
  end
end
