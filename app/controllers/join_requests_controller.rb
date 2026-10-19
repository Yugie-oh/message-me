class JoinRequestsController < ApplicationController
  before_action :require_user
  before_action :set_checklist
  before_action :require_owner, only: :update

  def create
    if @checklist.member?(current_user)
      redirect_to @checklist and return
    end

    join_request = @checklist.join_requests.find_or_initialize_by(user: current_user)

    if join_request.persisted? && join_request.pending?
      redirect_to checklists_path, flash: { error: "You already asked to join this session" }
      return
    end

    join_request.status = "pending"
    if join_request.save
      ChecklistBroadcaster.roster_changed(@checklist)
      redirect_to checklists_path, flash: { success: "Request sent to #{@checklist.owner.username}" }
    else
      redirect_to checklists_path, flash: { error: "Could not send that request" }
    end
  end

  def update
    join_request = @checklist.join_requests.find(params[:id])

    unless join_request.pending?
      redirect_to @checklist, flash: { error: "That request was already handled" }
      return
    end

    case params[:status]
    when "approved"
      @checklist.memberships.find_or_create_by!(user: join_request.user) do |membership|
        membership.role = "member"
      end
      join_request.update!(status: "approved")
      ChecklistBroadcaster.roster_changed(@checklist)
      redirect_to @checklist, flash: { success: "#{join_request.user.username} joined the session" }
    when "declined"
      join_request.update!(status: "declined")
      ChecklistBroadcaster.roster_changed(@checklist)
      redirect_to @checklist, flash: { success: "Request declined" }
    else
      redirect_to @checklist, flash: { error: "Unknown response" }
    end
  end

  private

  def set_checklist
    @checklist = Checklist.find(params[:checklist_id])
  end

  def require_owner
    return if @checklist.owner?(current_user)

    redirect_to checklists_path, flash: { error: "Only the session owner can do that" }
  end
end
