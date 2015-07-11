class Dashing.Changepage extends Dashing.ClickableWidget

  ready: ->

  onData: (data) ->

  onClick: (node, event) ->
  	if @get('pageid')?
  		page = $('#'+@get('pageid')).index() + 1
  	else
  		page = @get('page')

  	Dashing.cycleDashboardsNow(
      boardnumber: page,
      stagger: @get('stagger'),
      fastTransition: @get('fasttransition'),
      transitiontype: @get('transitiontype'))
