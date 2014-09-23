window.Fulcrum ||= {}

class Fulcrum.ProjectVelocityView extends Backbone.View
  template: JST["templates/project_velocity"]
  className: "velocity"

  events:
    "click #velocity_value": "editVelocityOverride"

  initialize: ->
    _.bindAll this, "setFakeClass", "render"
    @override_view = new Fulcrum.ProjectVelocityOverrideView(model: @model)
    @listenTo @model, "change:userVelocity", @setFakeClass
    @listenTo @model, "rebuilt-iterations", @render
    return

  render: ->
    @$el.html @template(project: @model)
    @setFakeClass @model
    this

  editVelocityOverride: ->
    @$el.append @override_view.render().el
    return

  setFakeClass: (model) ->
    if model.velocityIsFake()
      @$el.addClass "fake"
    else
      @$el.removeClass "fake"
    return
