window.Fulcrum ||= {}
class Fulcrum.KeycutView extends Backbone.View
  template: JST["templates/keycut_view"]
  tagName: "div"
  id: "keycut-help"
  events:
    "click a.close": "closeWindow"

  render: ->
    $("#main").append $(@el).html(@template)
    this

  closeWindow: ->
    $("#" + @id).fadeOut ->
      $("#" + @id).remove()
      return

    return
