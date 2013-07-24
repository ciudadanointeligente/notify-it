# BASIC ACCOUNT INFORMATION AND DISPLAYING BASIC PAGES OF WEBSITE



# displays the subscriptions view in the account folder
# passes the following variables (taken from other files)
# when it goes to THAT url it displays THAT view
get '/account/subscriptions' do
  requires_login

  erb :"account/subscriptions", locals: {
    interests: current_user.interests.desc(:created_at),
    tags: current_user.tags.unscoped.asc(:name)
  }
end

# displays the unsubcriber page
get '/account/unsubscribe' do
  requires_login "/login?redirect=/account/unsubscribe"

  erb :"account/unsubscribe"
end

# this actually performs the function of unsubscribing
# this is an action in the unsubscribe form
# QUESTION: current_user is from a gem
# note that it redirects to an actual view page
# QUESTION: what does event mean?
post '/account/unsubscribe/actually' do
  requires_login

  event = current_user.unsubscribe!
  Admin.user_unsubscribe current_user, event['data']

  redirect "/account/unsubscribe"
end

# another page that can be displayed
# it also passes variables
get '/account/settings' do
  requires_login

  erb :"account/settings", locals: {user: current_user}
end

# put replaces something
put '/account/settings' do
  requires_login

  # first, any attributes given under the user hash
  # attributes are the instance variables (as opposed to methods)
  # then we reset the attributes to the new paramaters
  current_user.attributes = params[:user]

  # special case for checkboxes, sigh
  if params[:user]
    ['announcements', 'sunlight_announcements'].each do |field|
      current_user.send "#{field}=", (["false", false, nil].include?(params[:user][field]) ? false : true)
    end
  end

  # second, if there is a 'password' param then we need to verify the old password and pass in the confirmation
  if params[:password].present?
    unless User.authenticate(current_user, params[:old_password])
      flash.now[:password] = "Incorrect current password."
      return erb :"/account/settings", locals: {user: current_user}
    end

    current_user.password = params[:password]
    current_user.password_confirmation = params[:password_confirmation]
    current_user.should_change_password = false
  end

  if current_user.save
    flash[:user] = "Your settings have been updated."
    flash[:password] = "Your password has been changed." if params[:password].present?
    redirect "/account/settings"
  else
    erb :"account/settings", locals: {user: current_user}
  end
end


# simpler version of the account settings update -
# doesn't require an existing password to change the current one, but
# does require the confirm_token (which will be new and
# different from the one we emailed). Redirects back to itself on error
# instead of the settings page.

# this deals with the logging in and logging out
get '/account/confirm' do
  log_out

  unless params[:confirm_token] and user = User.where(confirm_token: params[:confirm_token]).first
    halt 404 and return
  end

  log_in user

  # confirm user, getting here is good enough for that
  user.confirmed = true

  # reset the token for good measure
  user.new_confirm_token

  user.save!

  Admin.confirmed_user user

  redirect "/account/welcome"
end

get '/account/welcome' do
  requires_login

  # default form checkbox to announcements on,
  # if they're arriving here directly (not from a bad form submit)
  current_user.announcements = true

  erb :"account/welcome", locals: {user: current_user}
end

put '/account/welcome' do
  requires_login

  if params[:user]
    ['announcements', 'sunlight_announcements'].each do |field|
      current_user.send "#{field}=", (["false", false, nil].include?(params[:user][field]) ? false : true)
    end
  end

  if params[:password].present?
    current_user.password = params[:password]
    current_user.password_confirmation = params[:password_confirmation]
    current_user.should_change_password = false
  end

  if current_user.save
    flash[:user] = "Your settings have been updated."
    redirect "/account/settings"
  else
    flash.now[:password] = "Your passwords did not match."
    erb :"account/welcome", locals: {user: current_user}
  end
end

put '/account/phone' do
  requires_login

  current_user.phone = params[:user]['phone']

  if Phoner::Phone.valid?(current_user.phone) and current_user.valid?

    # manually set to false, in case the phone number was set and is changing
    current_user.phone_confirmed = false

    current_user.new_phone_verify_code
    current_user.save!

    SMS.deliver! "Verification Code", current_user.phone, User.phone_verify_message(current_user.phone_verify_code)

    flash[:phone] = "We've sent you a text with a verification code."
    redirect "/account/settings"
  else
    flash[:phone] = "Phone number is invalid, or taken."
    redirect "/account/settings"
  end
end

post '/account/phone/confirm' do
  requires_login

  if params[:phone_verify_code] == current_user.phone_verify_code
    current_user.phone_verify_code = nil
    current_user.phone_confirmed = true
    current_user.save!
    flash[:phone] = "Your phone number has been verified."
  else
    flash[:phone] = "Your verification code did not match. You can resend the code, if you've lost it."
  end

  redirect "/account/settings"
end

post '/account/phone/resend' do
  requires_login

  current_user.new_phone_verify_code
  current_user.save!
  SMS.deliver! "Resend Verification Code", current_user.phone, User.phone_verify_message(current_user.phone_verify_code)

  flash[:phone] = "We've sent you another verification code."
  redirect "/account/settings"
end