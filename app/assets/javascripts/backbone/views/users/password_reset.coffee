class audiencias.views.PasswordReset extends Backbone.View
  template: JST["backbone/templates/users/password_reset"]
  sendResetLink: JST["backbone/templates/users/send_reset_link"]
  changePassword: JST["backbone/templates/users/change_password"]
  id: 'password-reset'

  events: 
    'click #submit-email': 'validateEmailRequest'
    'click #submit-password.enabled': 'sendNewPassword'
    'input #password': 'updateSubmitButton'
    'input #password-confirm': 'updateSubmitButton'
    'keyup #person-id': 'sendEmailIfEnter'
    'keyup #password': 'submitNewPasswordIfEnter'
    'keyup #password-confirm': 'submitNewPasswordIfEnter'

  renderSendResetLink: ->
    @$el.html(@template())
    @$el.find('#password-reset-card').html(@sendResetLink())

  renderUpdatePasswordForm: (formOptions) ->
    @$el.html(@template())
    form = @changePassword(formOptions)
    @$el.find('#password-reset-card').html(form)

  validateEmailRequest: =>
    idInput = @$el.find('#person-id')
    hasId = idInput.val().trim().length > 0
    idInput.toggleClass('invalid', !hasId)

    if hasId
      @sendResetEmail()
   
  sendResetEmail: =>
    data = {
      person_id: @$el.find('#person-id').val(),
      id_type: @$el.find('#id-type').val()
    }
    $.ajax({
      type: 'POST',
      url: '/resetear_credenciales', 
      data: data,
      success: @showEmailSentMessage
    })

  showEmailSentMessage: =>
    messageOptions = {
      icon: 'pass',
      confirmation: false,
      text: {
        main: 'Se le ha enviado la recuperación de contraseña a su mail.',
        secondary: 'En caso de no usar el mismo mail o no haber recibido la recuperación de contraseña, verifique en Spam o comuníquese con su administrador.'
      },
      callback: {
        confirm: => 
          NProgress.start()
          window.location.href = "/intranet"
      }
    }
    message = new audiencias.views.ImportantMessage(messageOptions)

  updateSubmitButton: =>
    passwordInput = @$el.find('#password')
    passwordValue = passwordInput.val()

    passwordConfirmInput = @$el.find('#password-confirm')
    passwordConfirmValue = passwordConfirmInput.val()

    if passwordValue.length >= 6 and passwordConfirmValue.length >= 6 and passwordValue == passwordConfirmValue
      @$el.find('#submit-password').removeClass('disabled').addClass('enabled')
    else
      @$el.find('#submit-password').addClass('disabled').removeClass('enabled')

  sendNewPassword: =>
    data = {
      password: @$el.find('#password').val()
    }
    $.ajax({
      type: 'POST',
      data: data,
      success: (response) =>
        if response.success
          @showPasswordChangedMessage()
    })

  showPasswordChangedMessage: =>
    messageOptions = {
      icon: 'pass',
      confirmation: false,
      text: {
        main: 'Se ha actualizado la contraseña.',
        secondary: 'Ya puede ingresar usando su nueva contraseña.'
      },
      callback: {
        confirm: => 
          NProgress.start()
          window.location.href = "/intranet"
      }
    }
    message = new audiencias.views.ImportantMessage(messageOptions)

  sendEmailIfEnter: (e) =>
    @validateEmailRequest() if e.keyCode == 13

  submitNewPasswordIfEnter: (e) =>
    if e.keyCode == 13 and @$el.find('#submit-password').hasClass('enabled')
      @sendNewPassword()