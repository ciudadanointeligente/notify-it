class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  field :subscription_type
  field :initialized, type: Boolean, default: false
  field :interest_in
  field :interest_id
  field :last_checked_at, type: Time

  # arbitrary set of parameters that may refine or alter the subscription (e.g. "state" => "NY")
  field :data, type: Hash, default: {}
  field :query_type # can't wait to ditch this

  # duplicated from interest
  def query; interest ? interest.query : @query; end
  def query=(obj); @query = obj; end

  index subscription_type: 1
  index initialized: 1
  index user_id: 1
  index interest_in: 1
  index last_checked_at: 1
  index interest_id: 1
  index user_id: 1

  has_many :seen_items
  has_many :deliveries
  belongs_to :user
  belongs_to :interest

  validates_presence_of :user_id
  validates_presence_of :subscription_type

  # this validation will fall
  validate do
    if interest_in.blank?
      errors.add(:base, "Enter a keyword or phrase to subscribe to.")
    end
  end

  scope :initialized, where(initialized: true)
  scope :uninitialized, where(initialized: false)

  # adapter class associated with a particular subscription
  def adapter
    Subscription.adapter_for subscription_type
  end

  def self.adapter_for(type)
    adapter_map[type]
  end

  def search(options = {})
    Subscriptions::Manager.search self, options
  end

  def search_name
    adapter.search_name self
  end

  def search_url(options = {})
    adapter.url_for self, :search, options
  end

  # convenience method - the 'data' field, but only keys where the adapter supports them
  def filters
    if @filters
      @filters
    else
      filter_fields = adapter.respond_to?(:filters) ? adapter.filters.keys : []
      fields = data.dup
      fields.keys.each {|key| fields.delete(key) unless filter_fields.include?(key)}
      @filters = fields
    end
  end

  def filter_name(field, value)
    if adapter.respond_to?(:filters)
      adapter.filters[field.to_s][:name].call value
    end
  end
end