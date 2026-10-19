function checklistRoot() {
  return document.getElementById("checklist");
}

function checklistCsrfToken() {
  var tag = document.querySelector("meta[name='csrf-token']");
  return tag ? tag.getAttribute("content") : "";
}

function currentUserId() {
  var root = checklistRoot();
  return root ? root.getAttribute("data-user-id") : "";
}

function editPolicy() {
  var root = checklistRoot();
  return root ? root.getAttribute("data-edit-policy") : "everyone";
}

function refreshEmptyState() {
  var empty = document.getElementById("empty-items");
  if (!empty) return;
  empty.classList.toggle("is-hidden", $("#items").children().length > 0);
}

function policyNote(policy) {
  var who = policy === "creator" ? "Only the creator can edit an item." : "Anyone in this session can edit an item.";
  return who + " Checking an item complete is open to everyone.";
}

function applyItemControls(scope) {
  var me = currentUserId();
  var creatorOnly = editPolicy() === "creator";
  $(scope).find(".checklist-item").addBack(".checklist-item").each(function() {
    var row = $(this);
    if (!row.is(".checklist-item")) return;
    var creatorId = String(row.attr("data-creator-id") || "");
    var lockedBy = String(row.attr("data-locked-by") || "");
    var lockedByOther = lockedBy !== "" && lockedBy !== me;
    var canEdit = !creatorOnly || creatorId === me;
    row.toggleClass("can-edit", canEdit && !lockedByOther && !row.hasClass("is-editing"));
    row.toggleClass("is-locked-by-other", lockedByOther);
    row.find(".item-lock").text(lockedByOther ? row.attr("data-locked-name") + " is editing" : "");
  });
}

function itemErrorText(xhr) {
  if (xhr.status === 409) return "Someone else is editing this item.";
  if (xhr.status === 403) return "Only the person who added this item can edit it.";
  if (xhr.status === 422) return "Add a short description before saving.";
  return "Could not save that change.";
}

function showItemError(row, text) {
  var note = row.find(".item-error-note");
  if (!note.length) {
    note = $("<div class='item-error-note'></div>");
    row.find(".item-copy").append(note);
  }
  note.text(text);
}

function enterEditMode(row) {
  var current = row.find(".item-body").text();
  var form = document.createElement("form");
  form.className = "item-edit-form";

  var input = document.createElement("input");
  input.type = "text";
  input.name = "body";
  input.maxLength = 200;
  input.required = true;
  input.value = current;
  input.setAttribute("aria-label", "Edit item");

  var save = document.createElement("button");
  save.type = "submit";
  save.className = "ui mini orange button";
  save.textContent = "Save";

  var cancel = document.createElement("button");
  cancel.type = "button";
  cancel.className = "ui mini button";
  cancel.setAttribute("data-cancel-edit", "true");
  cancel.textContent = "Cancel";

  form.appendChild(input);
  form.appendChild(save);
  form.appendChild(cancel);

  row.addClass("is-editing");
  row.find(".item-copy").empty().append(form);
  applyItemControls(row);
  input.focus();
  input.select();
}

function onChecklistMessage(data) {
  if (data.action === "item_created") {
    if (!$("#item_" + data.id).length) $("#items").append(data.html);
    applyItemControls("#item_" + data.id);
  } else if (data.action === "item_updated") {
    var existing = $("#item_" + data.id);
    var stillMine = existing.hasClass("is-editing") && String(data.editing_by_id || "") === currentUserId();
    if (existing.length && !stillMine) {
      existing.replaceWith(data.html);
      applyItemControls("#item_" + data.id);
    }
  } else if (data.action === "item_removed") {
    $("#item_" + data.id).remove();
  } else if (data.action === "members" && $("#members").length) {
    $("#members").replaceWith(data.html);
  } else if (data.action === "join_requests" && $("#join-requests").length) {
    $("#join-requests").replaceWith(data.html);
  } else if (data.action === "edit_policy") {
    var root = checklistRoot();
    if (root) root.setAttribute("data-edit-policy", data.edit_policy);
    var box = document.getElementById("edit-policy-creator");
    if (box) box.checked = data.edit_policy === "creator";
    var note = document.getElementById("edit-policy-note");
    if (note) note.textContent = policyNote(data.edit_policy);
    applyItemControls(document);
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
  var root = checklistRoot();
  applyItemControls(document);
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

$(document).on("click", "[data-edit-item]", function() {
  var button = $(this);
  var row = button.closest(".checklist-item");
  var itemId = row.attr("id");
  $.ajax({
    url: button.attr("data-lock-url"),
    method: "POST",
    headers: { "X-CSRF-Token": checklistCsrfToken() }
  }).done(function() {
    enterEditMode($("#" + itemId));
  }).fail(function(xhr) {
    showItemError($("#" + itemId), itemErrorText(xhr));
  });
});

$(document).on("submit", ".item-edit-form", function(event) {
  event.preventDefault();
  var form = $(this);
  var row = form.closest(".checklist-item");
  var button = row.find("[data-edit-item]");
  $.ajax({
    url: button.attr("data-save-url"),
    method: "PATCH",
    headers: { "X-CSRF-Token": checklistCsrfToken() },
    data: { item: { body: form.find("input[name=body]").val() } }
  }).fail(function(xhr) {
    showItemError(row, itemErrorText(xhr));
  });
});

$(document).on("click", "[data-cancel-edit]", function() {
  var row = $(this).closest(".checklist-item");
  var button = row.find("[data-edit-item]");
  row.removeClass("is-editing");
  $.ajax({
    url: button.attr("data-unlock-url"),
    method: "DELETE",
    headers: { "X-CSRF-Token": checklistCsrfToken() }
  }).fail(function() {
    window.location.reload();
  });
});
