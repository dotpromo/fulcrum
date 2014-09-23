window.Fulcrum ||= {}
class Fulcrum.Project extends Backbone.Model

  name: "project"
  defaults:
    default_velocity: 10

  # The ids of the columns, in the order that they appear by story weight
  columnIds: [
    "#done"
    "#in_progress"
    "#backlog"
    "#chilly_bin"
  ]

  milliseconds_in_a_day: 1000 * 60 * 60 * 24

  initialize: (args) ->
    @maybeUnwrap args
    @bind "change:last_changeset_id", @updateChangesets
    @stories = new Fulcrum.StoryCollection()
    @stories.url = @url() + "/stories"
    @stories.project = @
    @users = new Fulcrum.UserCollection()
    @users.url = @url() + "/users"
    @users.project = @
    @iterations = []
    return

  url: ->
    "/projects/" + @id

  # Return an array of the columns that appear after column, or an empty
  # array if the column is the last
  columnsAfter: (column) ->
    index = _.indexOf(@columnIds, column)

    # column was not found in the array
    throw column.toString() + " is not a valid column"  if index is -1
    @columnIds.slice index + 1

  # Return an array of the columns that appear before column, or an empty
  # array if the column is the first
  columnsBefore: (column) ->
    index = _.indexOf(@columnIds, column)

    # column was not found in the array
    throw column.toString() + " is not a valid column"  if index is -1
    @columnIds.slice 0, index


  # This method is triggered when the last_changeset_id attribute is changed,
  # which indicates there are changed or new stories on the server which need
  # to be loaded.
  updateChangesets: ->
    from = @previous("last_changeset_id")
    from = 0  if from is null
    to = @get("last_changeset_id")
    to = 0  if to is null
    model = this
    options =
      type: "GET"
      dataType: "json"
      success: (resp, status, xhr) =>
        model.handleChangesets resp
        return
      data:
        from: from
        to: to
      url: @url() + "/changesets"

    $.ajax options
    return

  # (Re)load each of the stories described in the provided changesets.
  handleChangesets: (changesets) ->
    that = this
    story_ids = _.map(changesets, (changeset) ->
      changeset.changeset.story_id
    )
    story_ids = _.uniq(story_ids)
    _.each story_ids, (story_id) ->

      # FIXME - Feature envy on stories collection
      story = that.stories.get(story_id)
      if story

        # This is an existing story on the collection, just reload it
        story.fetch()
      else

        # This is a new story, which is present on the server but we don't
        # have it locally yet.
        that.stories.add id: story_id
        story = that.stories.get(story_id)
        story.fetch()
      return

    return

  # Return the correct iteration number for a given date.
  getIterationNumberForDate: (compare_date) ->

    #var start_date = new Date(this.get('start_date'));
    start_date = @startDate()
    difference = Math.abs(compare_date.getTime() - start_date.getTime())
    days_apart = Math.round(difference / @milliseconds_in_a_day)
    Math.floor (days_apart / (@get("iteration_length") * 7)) + 1

  getDateForIterationNumber: (iteration_number) ->

    # The difference betweeen the start date in days.  Iteration length is
    # in weeks.
    difference = (7 * @get("iteration_length")) * (iteration_number - 1)
    start_date = @startDate()
    iteration_date = new Date(start_date)
    iteration_date.setDate start_date.getDate() + difference
    iteration_date

  currentIterationNumber: ->
    @getIterationNumberForDate new Date()

  startDate: ->
    start_date = undefined
    if @get("start_date")

      # Parse the date string into an array of [YYYY, MM, DD] to
      # ensure identical date behaviour across browsers.
      dateArray = @get("start_date").split("/")
      year = parseInt(dateArray[0], 10)

      # Month is zero indexed
      month = parseInt(dateArray[1], 10) - 1
      day = parseInt(dateArray[2], 10)
      start_date = new Date(year, month, day)
    else
      start_date = new Date()

    # Is the specified project start date the same week day as the iteration
    # start day?
    if start_date.getDay() is @get("iteration_start_day")
      start_date
    else

      # Calculate the date of the nearest prior iteration start day to the
      # specified project start date.  So if the iteration start day is
      # set to Monday, but the project start date is set to a specific
      # Thursday, return the Monday before the Thursday.  A greater
      # mathemtician than I could probably do this with the modulo.
      day_difference = start_date.getDay() - @get("iteration_start_day")

      # The iteration start day is after the project start date, in terms of
      # day number
      day_difference = day_difference + 7  if day_difference < 0
      new Date(start_date - day_difference * @milliseconds_in_a_day)


  # Override the calculated velocity with a user defined value.  If this
  # value is different to the calculated velocity, the velocityIsFake
  # attribute will be set to true.
  velocity: (userVelocity) ->
    if userVelocity isnt `undefined`
      userVelocity = 1  if userVelocity < 1
      if userVelocity is @calculateVelocity()
        @unset "userVelocity"
      else
        @set userVelocity: userVelocity
    if @get("userVelocity")
      @get "userVelocity"
    else
      @calculateVelocity()

  velocityIsFake: ->
    @get("userVelocity") isnt `undefined`

  calculateVelocity: ->
    if @doneIterations().length is 0
      @get "default_velocity"
    else

      # TODO Make number of iterations configurable
      numIterations = 3
      iterations = @doneIterations()

      # Take a maximum of numIterations from the end of the array
      iterations = iterations.slice(iterations.length - numIterations)  if iterations.length > numIterations
      pointsArray = _.invoke(iterations, "points")
      sum = _.reduce(pointsArray, (memo, points) ->
        memo + points
      , 0)
      velocity = Math.floor(sum / pointsArray.length)
      (if velocity < 1 then 1 else velocity)

  revertVelocity: ->
    @unset "userVelocity"
    return

  doneIterations: ->
    _.select @iterations, (iteration) ->
      iteration.get("column") is "#done"


  rebuildIterations: ->

    #
    # Done column
    #
    that = this

    # Clear the project iterations
    @iterations = []

    # Reset all story column values.  Required as the story.column values
    # may have been changed from their default values by a prior run of
    # this method.
    @stories.invoke "setColumn"
    doneIterations = _.groupBy(@stories.column("#done"), (story) ->
      story.iterationNumber()
    )

    # groupBy() returns an object with keys of the iteration number
    # and values of the stories array.  Ensure the keys are sorted
    # in numeric order.
    doneNumbers = _.keys(doneIterations).sort((left, right) ->
      left - right
    )
    _.each doneNumbers, (iterationNumber) ->
      stories = doneIterations[iterationNumber]
      iteration = new Fulcrum.Iteration(
        number: iterationNumber
        stories: stories
        column: "#done"
      )
      that.appendIteration iteration, "#done"
      return

    currentIteration = new Fulcrum.Iteration(
      number: @currentIterationNumber()
      stories: @stories.column("#in_progress")
      maximum_points: @velocity()
      column: "#in_progress"
    )
    @appendIteration currentIteration, "#done"

    #
    # Backlog column
    #
    backlogIteration = new Fulcrum.Iteration(
      number: currentIteration.get("number") + 1
      column: "#backlog"
      maximum_points: @velocity()
    )
    @appendIteration backlogIteration, "#backlog"
    _.each @stories.column("#backlog"), (story) ->

      # The in progress iteration usually needs to be filled with the first
      # few stories from the backlog, unless the points total of the stories
      # in progress already equal or exceed the project velocity
      if currentIteration.canTakeStory(story)

        # On initialisation, a stories column is determined based on the
        # story state.  For unstarted stories this defaults to #backlog.
        # Stories matched here need this value overridden to #in_progress
        story.column = "#in_progress"
        currentIteration.get("stories").push story
        return
      unless backlogIteration.canTakeStory(story)

        # Iterations sometimes 'overflow', i.e. an iteration may contain a
        # 5 point story but the project velocity is 1.  In this case, the
        # next iteration that can have a story added is the current + 4.
        nextNumber = backlogIteration.get("number") + 1 + Math.ceil(backlogIteration.overflowsBy() / that.velocity())
        backlogIteration = new Fulcrum.Iteration(
          number: nextNumber
          column: "#backlog"
          maximum_points: that.velocity()
        )
        that.appendIteration backlogIteration, "#backlog"
      backlogIteration.get("stories").push story
      return

    _.each @iterations, (iteration) ->
      iteration.project = that
      return

    @trigger "rebuilt-iterations"
    return

  # Adds an iteration to the project.  Creates empty iterations to fill any
  # gaps between the iteration number and the last iteration number added.
  appendIteration: (iteration, columnForMissingIterations) ->
    lastIteration = _.last(@iterations)

    # If there is a gap between the last iteration and this one, fill
    # the gap with empty iterations
    @iterations = @iterations.concat(Fulcrum.Iteration.createMissingIterations(columnForMissingIterations, lastIteration, iteration))
    @iterations.push iteration
    return
