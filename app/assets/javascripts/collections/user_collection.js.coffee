window.Fulcrum ||= {}

class Fulcrum.UserCollection extends Backbone.Collection
  model: Fulcrum.User

  forSelect: ->
    @map (user) ->
      [
        user.get("name")
        user.id
      ]
