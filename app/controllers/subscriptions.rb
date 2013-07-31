# MANAGING SUBSCRIPTIONS
# (I.E. DELETING THEM OR UDPATING THEM)

# another potential html action (upon hitting a button, for example)
# QUESTION: an interest can be of ANY type?
# QUESTION: what does it mean that interests are stored under current_user?
# delete any interest, by ID (from the subscriptions management page)


get '/interest/delete/:interest_id/:user_id' do

  present_user = User.find_by(_id: params[:user_id])
  
  # check that it exists
  if (present_user &&
    interest = present_user.interests.find(params[:interest_id]))
    interest.destroy

    # handles all the ERROR CODE
    halt 200
  else
    halt 404 # NOT FOUND: hence, it does not exist
  end

  render template: ENV['hostname']

end


delete '/interest/:interest_id/:user_id' do

  present_user = User.find_by(_id: params[:user_id])
  
  # check that it exists
  if (present_user &&
    interest = present_user.interests.find(params[:interest_id]))
    interest.destroy

    # handles all the ERROR CODE
    halt 200
  else
    halt 404 # NOT FOUND: hence, it does not exist
  end
end


# update any interest, by ID (from the subscriptions management page)
put '/interest/:id' do
  requires_login

  unless interest = current_user.interests.find(params[:id])
    halt 404 and return false
  end

  if params[:interest]['notifications']
    interest.notifications = params[:interest]['notifications']
  end

  tags = []
  if params[:interest]['tags']
    halt 500 if interest.tag? # no!
    interest.new_tags = params[:interest]['tags']
    tags = interest.tags.map do |name| 
      current_user.tags.find_or_initialize_by name: name
    end
  end

  if interest.save
    # should be guaranteed to be safe
    tags.each {|tag| tag.save! if tag.new_record?}

    pane = partial "account/tags", engine: :erb, locals: {tags: current_user.tags}
    json 200, {
      interest_tags: interest.tags,
      notifications: interest.notifications,
      tags_pane: pane
    }
  else
    halt 500
  end
end