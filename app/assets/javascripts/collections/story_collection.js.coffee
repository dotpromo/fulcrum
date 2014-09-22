window.Fulcrum ||= {}

class Fulcrum.StoryCollection extends Backbone.Collection
  model: Fulcrum.Story

  initialize: ->
    @on "change:position", @sort
    @on "change:state", @sort
    @on "change:estimate", @sort
    @on "change:labels", @addLabelsFromStory
    @on "add", @addLabelsFromStory
    @on "reset", @resetLabels
    @on "change", @resetLabels
    @labels = []
    return

  comparator: (story) ->
    story.position()

  next: (story) ->
    @at @indexOf(story) + 1

  previous: (story) ->
    @at @indexOf(story) - 1

  # Returns all the stories in the named column, either #done, #in_progress,
  # #backlog or #chilly_bin
  column: (column) ->
    @select (story) ->
      story.column is column

  # Returns an array of the stories in a set of columns.  Pass an array
  # of the column names accepted by column().
  columns: (columns) ->
    _.flatten _.map(columns, (column) =>
      @column column
    )

  # Takes comma separated string of labels and adds them to the list of
  # availableLabels.  Any that are already present are ignored.
  addLabels: (labels) ->
    @labels = _.union(@labels, labels)

  addLabelsFromStory: (story) ->
    @addLabels story.labels()

  resetLabels: ->
    collection = this
    collection.each (story) ->
      collection.addLabelsFromStory story
      return

    return
