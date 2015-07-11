class Dashing.Stmode extends Dashing.ClickableWidget
  constructor: ->
    super
    @queryState()

  @accessor 'mode',
    get: -> @_mode ? "Unknown"
    set: (key, value) -> @_mode = value

  queryState: ->
    $.get '/smartthings/dispatch',
      widgetId: @get('id'),
      deviceType: 'mode'
      (data) =>
        json = JSON.parse data
        @set 'mode', json.mode

  ready: ->

  onData: (data) ->

  onClick: (event) ->
    if @get('pageid')?
      page = $('#'+@get('pageid')).index() + 1

      Dashing.cycleDashboardsNow(
        boardnumber: page,
        stagger: @get('stagger'),
        fastTransition: @get('fasttransition'),
        transitiontype: @get('transitiontype'))
