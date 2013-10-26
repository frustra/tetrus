class Tetrus.LayoutView extends Batman.View
  constructor: ->
    super

    Tetrus.observe 'currentRoute', (route) =>
      @set('routingSection', route.get('controller'))
      @set('routingPage', route.get('action'))

  @accessor 'title', ->
    section = @get('routingSection')
    "#{section} ~ tetrus"

  @accessor 'path', ->
    section = @get('routingSection')

