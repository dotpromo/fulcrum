window.Fulcrum ||= {}

class Fulcrum.ProjectVelocityOverrideView extends Backbone.View

  className: "velocity_override_container"
  events:
    "click button[name=apply]": "changeVelocity"
    "click button[name=revert]": "revertVelocity"
    "keydown input[name=override]": "keyCapture"

  template: JST["templates/project_velocity_override"]

  render: ->
    @$el.html @template(project: @model)
    @delegateEvents()
    this

  changeVelocity: ->
    @model.velocity @requestedVelocityValue()
    @$el.remove()
    false

  revertVelocity: ->
    @model.revertVelocity()
    @$el.remove()
    false

  requestedVelocityValue: ->
    parseInt @$("input[name=override]").val(), 10

  keyCapture: (e) ->
    @changeVelocity()  if e.keyCode is "13"
    return
