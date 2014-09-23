window.Fulcrum ||= {}
class Fulcrum.IterationView extends Backbone.View

  template: JST["templates/iteration"]
  className: "iteration"

  render: ->
    @$el.html @template(
      iteration: @model
      view: this
    )
    this

  # Returns the number of points in the iteration, unless the iteration is
  # the current iteration, in which case returns 'accepted/total' points.
  points: ->
    if @model.get("column") is "#in_progress"
      @model.acceptedPoints() + "/" + @model.points()
    else
      @model.points()
