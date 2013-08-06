# THIS IS TO SEACH RESULTS

# NOTES
# (1) subscription type means like 'bills in congress' or 'speeches in congress'
# (2) the query are the specific words typed in
# (3) the type of query is either simple or advanced

# NOTE: I need to ues params to make the routed parameters accessible

get '/search/:subscription_type/:query/?:query_type?' do

  #check if valid subscription type first (if it's in the array of types and all)
  halt 404 and return unless (search_types + ["all"]).include?(params[:subscription_type])

  # strips the query (stripped query is defined below)
  query = search_stripped_query
  
  # Q: the whole search becomes an interest in case you'd like to ADD it
  # search_interest_for is a function that takes in a query and a search_type
  # is this to check if you've already listed it as an interest?
  interest = search_interest_for_on_website query, params[:subscription_type]

  puts "<interest_status>"
  puts interest.new_record?
  puts "<interest_status>"

  # if this is a new interest then it returns all existing subscriptions
  subscriptions = Interest.subscriptions_for interest

  # render the search skeleton, possibly with a hash of cached content keyed by search type
  # all the locals are encoded here for the search display
  erb :"search/search", layout: !pjax?, locals: {
    interest: interest,

    # tracks if the interest is already subscribed to
    # if it isn't it returns NIL (I believe)
    subscriptions: subscriptions,
    subscription: (subscriptions.size == 1 ? subscriptions.first : nil),

    cached: {}, # disabling for now, though leaving view's code path

    related_interests: related_interests(interest),
    query: query,
    title: page_title(interest)
  }
end

# This is to actually display the search results
# The actual searching appears to be within the subscriptions (ALL)
# They then appear in results

get '/fetch/search/:subscription_type/:query/?:query_type?' do
  query = search_stripped_query
  subscription_type = params[:subscription_type]

  # make a fake interest, it may not be the one that's really generating this search request
  interest = search_interest_for_on_website query, params[:subscription_type]
  subscription = Interest.subscriptions_for(interest).first

  page = params[:page].present? ? params[:page].to_i : 1

  puts "<params>"
  puts params
  puts "</params>"

  # only used to decide how many to display
  per_page = params[:per_page].present? ? params[:per_page].to_i : nil

  # perform the remote search, pass along page number and default per_page of 20
  results = subscription.search page: page, per_page: 20

  # if results is nil, it usually indicates an error in one of the remote services
  if results.nil?
    puts "[#{subscription_type}][#{query}][search] ERROR (unknown) while loading this"
  elsif results.is_a?(Hash)
    puts "[#{subscription_type}][#{query}][search] ERROR while loading this:\n\n#{JSON.pretty_generate results}"
    results = nil # frontend gets nil
  end

  items = erb :"search/items", layout: false, locals: {
    items: results,
    subscription: subscription,
    interest: interest,
    query: query,
    sole: (per_page.to_i > 5),
    page: page,
    per_page: per_page
  }

  headers["Content-Type"] = "application/json"
  {
    html: items,
    count: (results ? results.size : -1),
    sole: (per_page.to_i > 5),
    page: page,
    per_page: per_page
  }.to_json
end

post '/interests/search' do
  requires_login

  query = search_stripped_query

  interest = search_interest_for_on_website query, params[:search_type]
  halt 200 and return unless interest.new_record?

  if interest.save
    interest_pane = partial "search/related_interests", :engine => :erb, :locals => {
      related_interests: related_interests(interest),
      current_interest: interest,
      interest_in: interest.in
    }

    json 200, {
      interest_pane: interest_pane
    }
  else
    json 500, {
      errors: {
        interest: interest.errors.full_messages,
        subscription: (interest.subscriptions.any? ? interest.subscriptions.first.errors.full_messages : nil)
      }
    }
  end
end

delete '/interests/search' do
  requires_login

  query = stripped_query
  search_type = params[:search_type]

  interest = search_interest_for_on_website query, params[:search_type]
  halt 404 and return false if interest.new_record?

  interest.destroy

  interest_pane = partial "search/related_interests", :engine => :erb, :locals => {
    related_interests: related_interests(interest),
    current_interest: nil,
    interest_in: interest.in
  }

  json 200, {
    interest_pane: interest_pane
  }
end


# this is the actual form submission
# posting in the search box

post '/interests/search/:email' do

  if !(User.find_by(email: params[:email])) then
    user = User.new(email: params[:email], confirmed: true)
    user.save!
  end

  puts "<query_type>"
  puts params
  puts "</query_type>"

  query = stripped_query

  interest = search_interest_for query, params[:search_type]
  halt 200 and return unless interest.new_record?

  if interest.save
    interest_pane = partial "search/related_interests", :engine => :erb, :locals => {
      related_interests: related_interests(interest),
      current_interest: interest,
      interest_in: interest.in
    }

    json 200, {
      interest_pane: interest_pane
    }
  else
    json 500, {
      errors: {
        interest: interest.errors.full_messages,
        subscription: (interest.subscriptions.any? ? interest.subscriptions.first.errors.full_messages : nil)
      }
    }
  end

end

# this is to remove a search interest
# again, another form action if REMOVE alert is pressed
delete '/interests/search/:email' do

  query = stripped_query
  search_type = params[:search_type]

  # check that it's a new record
  interest = search_interest_for query, params[:search_type]
  halt 404 and return false if interest.new_record?

  interest.destroy

  interest_pane = partial "search/related_interests", :engine => :erb, :locals => {
    related_interests: related_interests(interest),
    current_interest: nil,
    interest_in: interest.in
  }

  json 200, {
    interest_pane: interest_pane
  }

end

# functions used above

helpers do

  def search_interest_for_on_website(query, search_type)
    Interest.for_search current_user, search_type, query, query_type, params[search_type]
  end

  def search_interest_for(query, search_type)
    present_user = User.find_by(email: params[:email])
    Interest.for_search present_user, search_type, query, query_type, params[search_type]
  end

  def related_interests(interest)
    if logged_in?
      current_user.interests.where(
        in_normal: interest.in_normal,
        interest_type: "search",
        query_type: query_type
      )
    end
  end

  def query_type
    params[:query_type] || "simple"
  end

  # get the query out of the words
  def stripped_query

    i_query = Hash.new
    i_query['q'] = params[:q] ? URI.decode(params[:q]).strip : nil
    literal_query = i_query['q']

    if literal_query.present? then query = "#{literal_query}"
    else query = ""
    end

    i_query['bill_id'] = params[:bill_id] ? URI.decode(params[:bill_id]).strip : nil
    i_query['stage'] = params[:stage] ? URI.decode(params[:stage]).strip : nil
    i_query['creation_date_min'] = params[:creation_date_min] ? URI.decode(params[:creation_date_min]).strip : nil
    i_query['creation_date_max'] = params[:creation_date_max] ? URI.decode(params[:creation_date_max]).strip : nil
    i_query['origin_chamber'] = params[:origin_chamber] ? URI.decode(params[:origin_chamber]).strip : nil

  for i in ['bill_id', 'stage', 'creation_date_min', 'creation_date_max', 'origin_chamber'] do
    # don't allow plain wildcards
    if i_query[i].present?
      j = i_query[i]

    if query_type == "simple"
      j = j.tr "\"", ""
    elsif query_type == "advanced"
      j = j.tr ",:", ""
    end

    j = CGI.escape j

    query << "&#{i}=#{j}"
    end
  end

    halt 404 unless query.present?
    halt 404 if query.size > 300 # sanity

    puts query
    query
  end

  def search_stripped_query

    puts "<query_desc>"
    puts params[:query]
    puts "</query_desc>"

    query = params[:query] ? URI.decode(params[:query]).strip : nil

    # don't allow plain wildcards
    query = query.gsub /^[^\w]*\*[^\w]*$/, ''

    if query_type == "simple"
      query = query.tr "\"", ""
    elsif query_type == "advanced"
      query = query.tr ",:", ""
    end

    halt 404 unless query.present?
    halt 404 if query.size > 300 # sanity

    query

  end

end