window.Fulcrum ||= {}
class window.Fulcrum.Note extends Backbone.Model
  _.extend @::, Fulcrum.SharedModelMethods
  name: "note"
  i18nScope: "activerecord.attributes.note"

  user: ->
    userId = @get("user_id")
    @collection.story.collection.project.users.get userId

  userName: ->
    user = @user()
    (if user then user.get("name") else "Author unknown")
