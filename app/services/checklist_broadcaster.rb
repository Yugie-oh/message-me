class ChecklistBroadcaster
  def self.item_created(item)
    broadcast_item "item_created", item
  end

  def self.item_updated(item)
    broadcast_item "item_updated", item
  end

  def self.item_removed(checklist, item_id)
    ChecklistChannel.broadcast_to checklist, action: "item_removed", id: item_id
  end

  def self.roster_changed(checklist)
    ChecklistChannel.broadcast_to(
      checklist,
      action: "members",
      html: render("checklists/members", checklist: checklist)
    )
    ChecklistChannel.broadcast_to(
      checklist,
      action: "join_requests",
      html: render("checklists/join_requests", checklist: checklist)
    )
  end

  def self.broadcast_item(action, item)
    ChecklistChannel.broadcast_to(
      item.checklist,
      action: action,
      id: item.id,
      html: render("items/item", item: item)
    )
  end

  def self.render(partial, locals)
    ApplicationController.render(partial: partial, locals: locals)
  end
  private_class_method :broadcast_item, :render
end
