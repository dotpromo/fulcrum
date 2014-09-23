window.Fulcrum ||= {}

class Fulcrum.Story extends Backbone.Model

  name: "story"
  i18nScope: "activerecord.attributes.story"
  timestampFormat: "d mmm yyyy, h:MMtt"

  defaults:
    events: []
    state: "unscheduled"
    story_type: "feature"

  initialize: (args) ->
    @on "change:state", @changeState
    @on "change:notes", @populateNotes

    # FIXME Call super()?
    @maybeUnwrap args
    @initNotes()
    @setColumn()
    return

  changeState: (model, new_value) ->
    if new_value is "started" and not @get("owned_by_id")
      model.set
        owned_by_id: model.collection.project.current_user.id
      , true
    model.setAcceptedAt()
    model.setColumn()
    return

  moveBetween: (before, after) ->
    beforeStory = @collection.get(before)
    afterStory = @collection.get(after)
    difference = (afterStory.position() - beforeStory.position()) / 2
    newPosition = difference + beforeStory.position()
    @set position: newPosition
    @collection.sort()
    this

  moveAfter: (beforeId) ->
    before = @collection.get(beforeId)
    after = @collection.next(before)
    if typeof after is "undefined"
      afterPosition = before.position() + 2
    else
      afterPosition = after.position()
    difference = (afterPosition - before.position()) / 2
    newPosition = difference + before.position()
    @set position: newPosition
    this

  moveBefore: (afterId) ->
    after = @collection.get(afterId)
    before = @collection.previous(after)
    if typeof before is "undefined"
      beforePosition = 0.0
    else
      beforePosition = before.position()
    difference = (after.position() - beforePosition) / 2
    newPosition = difference + beforePosition
    @set position: newPosition
    @collection.sort silent: true
    this


  setColumn: ->
    column = "#in_progress"
    switch @get("state")
      when "unscheduled"
        column = "#chilly_bin"
      when "unstarted"
        column = "#backlog"
      when "accepted"

        # Accepted stories remain in the in progress column if they were
        # completed within the current iteration.
        if @collection.project.currentIterationNumber() is @iterationNumber()
          column = "#in_progress"
        else
          column = "#done"
    @column = column
    return

  clear: ->
    @destroy()
    @view.remove()
    return

  estimable: ->
    if @get("story_type") is "feature"
      not @estimated()
    else
      false

  estimated: ->
    estimate = @get("estimate")
    not (estimate is `undefined` or estimate is null)

  point_values: ->
    @collection.project.get "point_values"


  # List available state transitions for this story
  events: ->
    switch @get("state")
      when "started"
        return ["finish"]
      when "finished"
        return ["deliver"]
      when "delivered"
        return [
          "accept"
          "reject"
        ]
      when "rejected"
        return ["restart"]
      when "accepted"
        return []
      else
        ["start"]


  # State machine transitions
  start: ->
    @set state: "started"
    return

  finish: ->
    @set state: "finished"
    return

  deliver: ->
    @set state: "delivered"
    return

  accept: ->
    @set state: "accepted"
    return

  reject: ->
    @set state: "rejected"
    return

  restart: ->
    @set state: "started"
    return

  position: ->
    parseFloat @get("position")

  className: ->
    className = "story " + @get("story_type")
    className += " unestimated"  if @estimable() and not @estimated()
    className


  # Returns the user that owns this Story, or undefined if no user owns
  # the Story
  owned_by: ->
    @collection.project.users.get @get("owned_by_id")

  requested_by: ->
    @collection.project.users.get @get("requested_by_id")

  created_at: ->
    d = new Date(@get("created_at"))
    d.format @timestampFormat

  hasDetails: ->
    typeof @get("description") is "string" or @hasNotes()

  iterationNumber: ->
    @collection.project.getIterationNumberForDate new Date(@get("accepted_at"))  if @get("state") is "accepted"


  # If the story state is 'accepted', and the 'accepted_at' attribute is not
  # set, set it to today's date.
  setAcceptedAt: ->
    if @get("state") is "accepted" and not @get("accepted_at")
      today = new Date()
      today.setHours 0
      today.setMinutes 0
      today.setSeconds 0
      today.setMilliseconds 0
      @set accepted_at: today
    return

  labels: ->
    return []  unless typeof @get("labels") is "string"
    _.map @get("labels").split(","), (label) ->
      $.trim label



  # Initialize the notes collection on this story, and populate if necessary
  initNotes: ->
    @notes = new Fulcrum.NoteCollection()
    @notes.story = this
    @populateNotes()
    return


  # Resets this stories notes collection
  populateNotes: ->
    notes = @get("notes") or []
    @notes.reset notes
    return


  # Returns true if any of the story has any saved notes.
  hasNotes: ->
    @notes.any (note) ->
      not note.isNew()

_.defaults Fulcrum.Story::, Fulcrum.SharedModelMethods
