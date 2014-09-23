window.Fulcrum ||= {}

class Fulcrum.ProjectView extends Backbone.View

  initialize: ->
    @columns = {}
    _.bindAll this, "addStory", "addAll", "render"
    @listenTo @model.stories, "add", @addStory
    @listenTo @model.stories, "reset", @addAll
    @listenTo @model.stories, "all", @render
    @listenTo @model, "change:userVelocity", @addAll
    @model.stories.fetch()
    return

  # Triggered when the 'Add Story' button is clicked
  newStory: ->
    @model.stories.add [
      events: []
      editing: true
    ]
    return

  addStory: (story, column) ->
    # If column is blank determine it from the story.  When the add event
    # is bound on a collection, the callback sends the collection as the
    # second argument, so also check that column is a string and not an
    # object for those cases.
    column = story.column  if typeof column is "undefined" or typeof column isnt "string"
    view = new Fulcrum.StoryView(model: story).render()
    @appendViewToColumn view, column
    view.setFocus()
    return

  appendViewToColumn: (view, columnName) ->
    $(columnName).append view.el
    return

  addIteration: (iteration) ->
    that = this
    column = iteration.get("column")
    view = new Fulcrum.IterationView(model: iteration).render()
    @appendViewToColumn view, column
    _.each iteration.stories(), (story) ->
      that.addStory story, column
      return

    return

  addAll: ->
    $(".loading_screen").show()
    that = this
    $("#done").html ""
    $("#in_progress").html ""
    $("#backlog").html ""
    $("#chilly_bin").html ""
    @model.rebuildIterations()

    # Render each iteration
    _.each @model.iterations, (iteration) ->
      column = iteration.get("column")
      that.addIteration iteration
      return


    # Render the chilly bin.  This needs to be rendered separately because
    # the stories don't belong to an iteration.
    _.each @model.stories.column("#chilly_bin"), (story) ->
      that.addStory story
      return

    $(".loading_screen").hide()
    return

  scaleToViewport: ->
    storyTableTop = $("table.stories tbody").offset().top

    # Extra for the bottom padding and the
    extra = 100
    height = $(window).height() - (storyTableTop + extra)
    $(".storycolumn").css "height", height + "px"
    return

  notice: (message) ->
    $.gritter.add message
    return

  addColumnView: (id, view) ->
    @columns[id] = view
    return
