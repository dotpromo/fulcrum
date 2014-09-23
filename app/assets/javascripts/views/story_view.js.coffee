window.Fulcrum ||= {}
class Fulcrum.StoryView extends Fulcrum.FormView
  template: JST["templates/story"]
  tagName: "div"
  initialize: ->
    _.bindAll this, "render", "highlight", "moveColumn", "setClassName", "transition", "estimate", "disableForm", "renderNotes", "renderNotesCollection", "addEmptyNote"

    # Rerender on any relevant change to the views story
    @listenTo @model, "change", @render
    @listenTo @model, "change:title", @highlight
    @listenTo @model, "change:description", @highlight
    @listenTo @model, "change:column", @highlight
    @listenTo @model, "change:state", @highlight
    @listenTo @model, "change:position", @highlight
    @listenTo @model, "change:estimate", @highlight
    @listenTo @model, "change:story_type", @highlight
    @listenTo @model, "change:column", @moveColumn
    @listenTo @model, "change:estimate", @setClassName
    @listenTo @model, "change:state", @setClassName
    @listenTo @model, "change:notes", @addEmptyNote
    @listenTo @model, "change:notes", @renderNotesCollection
    @listenTo @model, "render", @hoverBox

    # Supply the model with a reference to it's own view object, so it can
    # remove itself from the page when destroy() gets called.
    @model.view = this
    if @model.id
      @id = @el.id = @model.id
      @$el.attr "id", "story-" + @id
      @$el.data "story-id", @id

    # Set up CSS classes for the view
    @setClassName()

    # Add an empty note to the collection
    @addEmptyNote()
    return

  events:
    'click': "startEdit"
    "click #submit": "saveEdit"
    "click #cancel": "cancelEdit"
    "click .transition": "transition"
    "click input.estimate": "estimate"
    "click #destroy": "clear"
    "click #edit-description": "editDescription"
    'sortupdate': "sortUpdate"


  # Triggered whenever a story is dropped to a new position
  sortUpdate: (ev, ui) ->

    # The target element, i.e. the StoryView.el element
    target = $(ev.target)

    # Initially, try and get the id's of the previous and / or next stories
    # by just searching up above and below in the DOM of the column position
    # the story was dropped on.  The case where the column is empty is
    # handled below.
    previous_story_id = target.prev(".story").data("story-id")
    next_story_id = target.next(".story").data("story-id")

    # Set the story state if drop column is chilly_bin or backlog
    column = target.parent().attr("id")
    if column is "backlog" or (column is "in_progress" and @model.get("state") is "unscheduled")
      @model.set state: "unstarted"
    else @model.set state: "unscheduled"  if column is "chilly_bin"

    # If both of these are unset, the story has been dropped on an empty
    # column, which will be either the backlog or the chilly bin as these
    # are the only columns that can receive drops from other columns.
    if typeof previous_story_id is "undefined" and typeof next_story_id is "undefined"
      beforeSearchColumns = @model.collection.project.columnsBefore("#" + column)
      afterSearchColumns = @model.collection.project.columnsAfter("#" + column)
      previousStory = _.last(@model.collection.columns(beforeSearchColumns))
      nextStory = _.first(@model.collection.columns(afterSearchColumns))
      previous_story_id = previousStory.id  unless typeof previousStory is "undefined"
      next_story_id = nextStory.id  unless typeof nextStory is "undefined"
    unless typeof previous_story_id is "undefined"
      @model.moveAfter previous_story_id
    else unless typeof next_story_id is "undefined"
      @model.moveBefore next_story_id
    else

      # The only possible scenario that we should reach this point under
      # is if there is only one story in the collection, so there is no
      # previous or next story.  If this is not the case then something
      # has gone wrong.
      throw "Unable to determine previous or next story id for dropped story"  unless @model.collection.length is 1
    @model.save()
    return

  transition: (ev) ->

    # The name of the function that needs to be called on the model is the
    # value of the form button that was clicked.
    transitionEvent = ev.target.value
    @saveInProgress = true
    @render()
    @model[transitionEvent] silent: true
    that = this
    @model.save null,
      success: (model, response) ->
        that.saveInProgress = false
        that.render()
        return

      error: (model, response) ->
        json = $.parseJSON(response.responseText)
        window.projectView.notice
          title: I18n.t("save error")
          text: model.errorMessages()

        that.saveInProgress = false
        that.render()
        return

    return

  estimate: (ev) ->
    @saveInProgress = true
    @render()
    @model.set estimate: ev.target.value
    that = this
    @model.save null,
      success: (model, response) ->
        that.saveInProgress = false
        that.render()
        return

      error: (model, response) ->
        json = $.parseJSON(response.responseText)
        window.projectView.notice
          title: I18n.t("save error")
          text: model.errorMessages()

        that.saveInProgress = false
        that.render()
        return

    return


  # Move the story to a new column
  moveColumn: ->
    @$el.appendTo @model.get("column")
    return

  startEdit: (e) ->
    if @eventShouldExpandStory(e)
      @model.set
        editing: true
        editingDescription: false

      @removeHoverbox()
    return


  # When a story is clicked, this method is used to check whether the
  # corresponding click event should expand the story into its form view.
  eventShouldExpandStory: (e) ->

    # Shouldn't expand if it's already expanded.
    return false  if @model.get("editing")

    # Should expand if the click wasn't on one of the buttons.
    not $(e.target).is("input")

  cancelEdit: ->
    @model.set editing: false

    # If the model was edited, but the edits were deemed invalid by the
    # server, the local copy of the model will still be invalid and have
    # errors set on it after cancel.  So, reload it from the server, which
    # will return the attributes to their true state.
    if @model.hasErrors()
      @model.unset "errors"
      @model.fetch()

    # If this is a new story and cancel is clicked, the story and view
    # should be removed.
    @model.clear()  if @model.isNew()
    return

  saveEdit: ->
    @disableForm()

    # Call this here to ensure the story gets it's accepted_at date set
    # before the story collection callbacks are run if required.  The
    # collection callbacks need this to be set to know which iteration to
    # put an accepted story in.
    @model.setAcceptedAt()
    that = this
    @model.save null,
      success: (model, response) ->
        that.model.set editing: false
        that.enableForm()
        return

      error: (model, response) ->
        json = $.parseJSON(response.responseText)
        model.set
          editing: true
          errors: json.story.errors

        window.projectView.notice
          title: I18n.t("Save error")
          text: model.errorMessages()

        that.enableForm()
        return

    return


  # Delete the story and remove it's view element
  clear: ->
    @model.clear()  if confirm("Are you sure you want to destroy this story?")
    return

  editDescription: ->
    @model.set editingDescription: true
    @render()
    return


  # Visually highlight the story if an external change happens
  highlight: ->

    # Workaround for http://bugs.jqueryui.com/ticket/5506
    @$el.effect "highlight", {}, 3000  if @$el.is(":visible")  unless @model.get("editing")
    return

  render: ->
    if @model.get("editing") is true
      @$el.empty()
      @$el.addClass "editing"
      @$el.append @makeFormControl((div) ->
        $(div).addClass "story-controls"
        $(div).append @submit()
        $(div).append @destroy()  unless @model.isNew()
        $(div).append @cancel()
        return
      )
      @$el.append @makeFormControl((div) ->
        $(div).append @textField("title",
          class: "title"
          placeholder: I18n.t("story title")
        )
        return
      )
      @$el.append @makeFormControl(
        name: "estimate"
        label: true
        control: @select("estimate", @model.point_values(),
          blank: "No estimate"
        )
      )
      @$el.append @makeFormControl(
        name: "story_type"
        label: true
        control: @select("story_type", [
          "feature"
          "chore"
          "bug"
          "release"
        ])
      )
      @$el.append @makeFormControl(
        name: "state"
        label: true
        control: @select("state", [
          "unscheduled"
          "unstarted"
          "started"
          "finished"
          "delivered"
          "accepted"
          "rejected"
        ])
      )
      @$el.append @makeFormControl(
        name: "requested_by_id"
        label: true
        control: @select("requested_by_id", @model.collection.project.users.forSelect(),
          blank: "---"
        )
      )
      @$el.append @makeFormControl(
        name: "owned_by_id"
        label: true
        control: @select("owned_by_id", @model.collection.project.users.forSelect(),
          blank: "---"
        )
      )
      @$el.append @makeFormControl(
        name: "labels"
        label: true
        control: @textField("labels")
      )
      @$el.append @makeFormControl((div) ->
        $(div).append @label("description", "Description")
        $(div).append "<br/>"
        if @model.isNew() or @model.get("editingDescription")
          $(div).append @textArea("description")
        else
          description = @make("div")
          $(description).addClass "description"
          $(description).html window.md.makeHtml(@model.escape("description"))
          $(div).append description
          $(description).after @make("input",
            id: "edit-description"
            type: "button"
            value: I18n.t("edit")
          )
        return
      )
      @initTags()
      @renderNotes()
    else
      @$el.removeClass "editing"
      @$el.html @template(
        story: @model
        view: this
      )
    @hoverBox()
    this

  setClassName: ->
    className = [
      "story"
      @model.get("story_type")
      @model.get("state")
    ].join(" ")
    className += " unestimated"  if @model.estimable() and not @model.estimated()
    @className = @el.className = className
    this

  saveInProgress: false
  disableForm: ->
    @$el.find("input,select,textarea").attr "disabled", "disabled"
    @$el.find("a.collapse,a.expand").removeClass(/icons-/).addClass "icons-throbber"
    return

  enableForm: ->
    @$el.find("a.collapse").removeClass(/icons-/).addClass "icons-collapse"
    return

  initTags: ->
    model = @model
    $input = @$el.find("input[name='labels']")
    $input.tagit availableTags: model.collection.labels

    # Manually bind labels for now
    $input.bind "change", ->
      model.set labels: $(this).val()
      return

    return

  renderNotes: ->
    if @model.notes.length > 0
      el = @$el
      el.append "<hr/>"
      el.append "<h3>" + I18n.t("notes") + "</h3>"
      el.append "<div class=\"notelist\"/>"
      @renderNotesCollection()
    return

  renderNotesCollection: ->
    notelist = @$("div.notelist")
    notelist.html ""
    @addEmptyNote()
    @model.notes.each (note) ->
      view = undefined
      if note.isNew()
        view = new Fulcrum.NoteForm(model: note)
      else
        view = new Fulcrum.NoteView(model: note)
      notelist.append view.render().el
      return

    return

  addEmptyNote: ->

    # Don't add an empty note if the story is unsaved.
    return  if @model.isNew()

    # Don't add an empty note if the notes collection already has a trailing
    # new Note.
    last = @model.notes.last()
    return  if last and last.isNew()

    # Add a new unsaved note to the collection.  This will be rendered
    # as a form which will allow the user to add a new note to the story.
    @model.notes.add()
    @$el.find("a.collapse,a.expand").removeClass(/icons-/).addClass "icons-throbber"
    return

  enableForm: ->
    @$el.find("a.collapse").removeClass(/icons-/).addClass "icons-collapse"
    return


  # FIXME Move to separate view
  hoverBox: ->
    view = this
    @$el.find(".popover-activate").popover
      title: ->
        view.model.get "title"

      content: ->
        JST["templates/story_hover"] story: view.model


      # A small delay to stop the popovers triggering whenever the mouse is
      # moving around
      delayIn: 200
      placement: view.hoverBoxPlacement
      html: true
      live: true

    return

  hoverBoxPlacement: ->

    # Gets called from a jQuery context, so this is set to the element that
    # the popover is bound to.
    position = $(this).position()
    windowWidth = $(window).width()

    # If the element is to the right of the vertical half way line in the
    # viewport, position the popover on the left.
    return "left"  if position.left > (windowWidth / 2)
    "right"

  removeHoverbox: ->
    $(".popover").remove()
    return

  initTags: ->
    model = @model
    $input = @$el.find("input[name='labels']")
    $input.tagit availableTags: model.collection.labels

    # Manually bind labels for now
    $input.bind "change", ->
      model.set labels: $(this).val()
      return

    return

  setFocus: ->
    @$("input.title").first().focus()  if @model.get("editing") is true
    return

  makeFormControl: (content) ->
    div = @make("div")
    if typeof content is "function"
      content.call this, div
    else if typeof content is "object"
      $div = $(div)
      if content.label
        $div.append @label(content.name)
        $div.append "<br/>"
      $div.append content.control
    div
