class audiencias.views.AudienceInfoSection extends Backbone.View
  template: JST["backbone/templates/operator/audience/main_info"]
  events:
    'click #edit-main-info': 'enableEdit'
    'click #confirm-main-info': 'submitChanges'

  initialize: (@options) ->
    @audience = @options.audience
    @audience.on('change', @render)

  render: =>
    @$el.html(@template(
      audience: @audience
    ))
    if @audience.get('editingInfo')
      @setDatePicker()
      @setMotifMaxLength()

  setDatePicker: =>
    @$el.find('#date').datetimepicker(
      format: 'H:i d/m/Y'
      lazyInit: true
    )

  setMotifMaxLength: =>
    motifTextarea = @$el.find('#motif')
    motifTextarea.bind('input propertychange', =>
      maxLength = motifTextarea.attr('maxlength')
      if motifTextarea.val().length > maxLength
        cuttedText = motifTextarea.val().substring(0, maxLength)
        motifTextarea.val(cuttedText)
    )

  enableEdit: =>
    @audience.set('editingInfo', true)

  submitChanges: =>
    data = { id: @audience.get('id') }
    someThingChanged = false

    newSummary = @$el.find('#summary').val()
    if newSummary != @audience.get('summary')
      data.summary = newSummary 
      someThingChanged = true

    newInterestInvoked = @$el.find('#invoked-interest-select').val()
    if newInterestInvoked != @audience.get('interest_invoked')
      data.interest_invoked = newInterestInvoked 
      someThingChanged = true

    newMotif = @$el.find('#motif').val()
    if newMotif != @audience.get('motif')
      data.motif = newMotif 
      someThingChanged = true

    newDate = @$el.find('#date').datetimepicker('getValue')
    if @isDate(newDate)
      newDate = newDate.toISOString()
      data.date = newDate if newDate != @audience.get('date')
      someThingChanged = true

    newPlace = @$el.find('#place').val().trim()
    if newPlace != @audience.get('place')
      data.place = newPlace
      someThingChanged = true

    if someThingChanged
      data.new = !!@audience.get('new')
      if data.new 
        data.obligee_id = audiencias.globals.obligees.currentObligee().get('id')
        data.author_id = audiencias.globals.users.currentUser().get('id')
      $.ajax(
        url: '/intranet/editar_audiencia'
        method: 'POST'
        data: { audience: data }
        success: (response) =>
          if response.success and response.audience
            response.audience.editingInfo = false
            response.audience.new = false
            if data.new 
              @audience.forceUpdate(response.audience)
            else
              audiencias.globals.audiences.updateAudience(response.audience)
      )
    else
      @audience.set('editingInfo', false)

  isDate: (date) ->
    Object.prototype.toString.call(date) == "[object Date]" 