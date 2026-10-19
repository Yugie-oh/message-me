class ChecklistsController < ApplicationController
  before_action :require_user
  before_action :set_checklist, only: [:show, :update]
  before_action :require_member, only: :show
  before_action :require_owner, only: :update

  def index
    @checklist = Checklist.new
    load_lists
  end

  def create
    @checklist = current_user.owned_checklists.build(checklist_params)

    ActiveRecord::Base.transaction do
      @checklist.save!
      @checklist.memberships.create!(user: current_user, role: "owner")
    end

    redirect_to @checklist, flash: { success: "Session created" }
  rescue ActiveRecord::RecordInvalid
    load_lists
    render :index
  end

  def show
    @item = Item.new
    @items = @checklist.items.includes(:user, :updated_by, :editing_by).order(:created_at)
  end

  def update
    policy = params.dig(:checklist, :edit_policy).to_s
    unless Checklist::EDIT_POLICIES.include?(policy)
      redirect_to @checklist, flash: { error: "Choose who can edit items" }
      return
    end

    @checklist.update!(edit_policy: policy)
    ChecklistBroadcaster.policy_changed(@checklist)
    redirect_to @checklist, flash: { success: "Edit permissions updated" }
  end

  private

  def set_checklist
    @checklist = Checklist.find(params[:id])
  end

  def require_member
    return if @checklist.member?(current_user)

    redirect_to checklists_path, flash: { error: "Join this session to see the list" }
  end

  def require_owner
    return if @checklist.owner?(current_user)

    redirect_to @checklist, flash: { error: "Only the session owner can change that" }
  end

  def checklist_params
    params.require(:checklist).permit(:title)
  end

  def load_lists
    joined_ids = Membership.where(user_id: current_user.id).select(:checklist_id)
    @checklists = Checklist.where(id: joined_ids).includes(:owner, :items, :memberships).order(updated_at: :desc)
    @available = Checklist.where.not(id: joined_ids).includes(:owner).order(created_at: :desc)
    @pending_checklist_ids = JoinRequest.pending.where(user_id: current_user.id, checklist_id: @available.select(:id)).pluck(:checklist_id)
  end
end
