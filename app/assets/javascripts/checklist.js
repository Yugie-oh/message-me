function checklistCsrfToken() {
  var tag = document.querySelector("meta[name='csrf-token']");
  return tag ? tag.getAttribute("content") : "";
}

function refreshEmptyState() {
  var empty = document.getElementById("empty-items");
  if (!empty) return;
  empty.classList.toggle("is-hidden", $("#items").children().length > 0);
}

function onChecklistMessage(data) {
  if (data.action === "item_created") {
    if (!$("#item_" + data.id).length) $("#items").append(data.html);
  } else if (data.action === "item_updated") {
    var existing = $("#item_" + data.id);
    if (existing.length) existing.replaceWith(data.html);
  } else if (data.action === "item_removed") {
    $("#item_" + data.id).remove();
  } else if (data.action === "members" && $("#members").length) {
    $("#members").replaceWith(data.html);
  } else if (data.action === "join_requests" && $("#join-requests").length) {
    $("#join-requests").replaceWith(data.html);
  }

  refreshEmptyState();
}

function unsubscribeChecklist() {
  if (App.checklistSubscription) {
    App.cable.subscriptions.remove(App.checklistSubscription);
    App.checklistSubscription = null;
  }
}

$(document).on("turbolinks:load", function() {
  unsubscribeChecklist();
  var root = document.getElementById("checklist");
  if (!root || !App.cable) return;

  App.checklistSubscription = App.cable.subscriptions.create(
    { channel: "ChecklistChannel", checklist_id: root.getAttribute("data-checklist-id") },
    { received: onChecklistMessage }
  );
});

$(document).on("turbolinks:before-cache", unsubscribeChecklist);

$(document).on("ajax:success", "#new-item-form", function() {
  this.reset();
  $("#item-error").hide();
});

$(document).on("ajax:error", "#new-item-form", function() {
  $("#item-error").show();
});

$(document).on("change", "[data-toggle-item]", function() {
  var checkbox = this;
  $.ajax({
    url: checkbox.getAttribute("data-url"),
    method: "PATCH",
    headers: { "X-CSRF-Token": checklistCsrfToken() },
    data: { item: { done: checkbox.checked } }
  }).fail(function() {
    checkbox.checked = !checkbox.checked;
  });
});
