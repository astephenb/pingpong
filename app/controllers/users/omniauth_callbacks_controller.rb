class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :verify_authenticity_token

  def google_oauth2
    user = User.from_omniauth(request.env['omniauth.auth'])
    if user.persisted?
      sign_in_and_redirect user, success: 'Signed in Through Google!'
    else
      session['devise.user_attributes'] = user.attributes
      # flash.notice = "You are almost Done! Please provide a password to finish setting up your account"
      redirect_to new_user_registration_url
    end
  end

end