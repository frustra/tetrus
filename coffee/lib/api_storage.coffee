class Tetrus.APIStorage extends Batman.RestStorage
  _addJsonExtension: (url) ->
    if url.indexOf('?') isnt -1 or url.substr(-5, 5) is '.json'
      return url
    url + '.json'

  urlForRecord: -> @_addJsonExtension(super)
  urlForCollection: -> @_addJsonExtension(super)

  constructor: ->
    super
    @defaultRequestOptions = type: 'json'

