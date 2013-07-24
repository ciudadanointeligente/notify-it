module Subscriptions  
  module Adapters

    class Billits
    
      MAX_PER_PAGE = 50
    
      # unclear what this is for!
      def self.filters
        {
          # todo: document_type, once more than one is present
        }
      end
      
      def self.url_for(subscription, function, options = {})
        query = subscription.query['query']
        return nil unless query.present?

        endpoint = "http://billit.ciudadanointeligente.org"

        url = "#{endpoint}/bills/search.json?"
        url << "q=#{CGI.escape query}"

        #if function == :check
          #url << "&posted_at__gte=#{1.month.ago.strftime "%Y-%m-%d"}"
        #end

        url << "&page=#{options[:page]}" if options[:page]
        per_page = (function == :search) ? (options[:per_page] || 20) : 40
        url << "&per_page=#{per_page}"

        url

          #puts "<subscription>"
          #puts subscription.interest_in
          #puts "</subscription>"
      end

      def self.url_for_detail(item_id, options = {})

        endpoint = "http://billit.ciudadanointeligente.org"

        url = "#{endpoint}/bills/search.json?"
        url << "uid=#{item_id}"

        url

      end

      def self.url_paginated(number, original_url)
        url = original_url
        url << "&page=#{number}"
        url
      end

      def self.url_for_sync(options = {})
        
        endpoint = "http://billit.ciudadanointeligente.org"
        url = "#{endpoint}/bills/search.json?"
        url << "title=educacion" # WILL HAVE TO GET RID OF THIS LATER
        
        # I NEED A URL FOR ALL
        #if options[:since] == "all"
          # ok, get everything

        # I NEED A URL SINCE A CERTAIN DATE
        #elsif options[:since] == "current_year"
          #url << "&creation_date__gte=#{Time.now.year}-01-01T00:00:00Z"
          #url << "&creation_date__lte=#{Time.now.year}-12-31"

        # can specify a single year (e.g. '2012', '2013')
        #elsif options[:since] =~ /^\d+$/
          #url << "&creation_date__gte=#{options[:since]}-01-01T00:00:00Z"
          #url << "&creation_date__lte=#{options[:since]}-12-31"

        # default to the last 3 days
        #else
          #url << "&creation_date__gte=#{3.days.ago.strftime "%Y-%m-%d"}T00:00:00Z"
        #end

        # ARE THERE PAGINATION OPTIONS?
        url << "&page=#{options[:page]}" if options[:page]
        url << "&per_page=#{MAX_PER_PAGE}"
        
        url

      end

      def self.title_for(bill)
        "Bill: #{bill['title']}"
      end

      def self.slug_for(bill)
        title_for bill
      end

      def self.search_name(subscription)
        "BillIt Reports"
      end

      def self.short_name(number, interest)
        "#{number > 1 ? "BillIt Reports" : "BillIt Report"}"
      end

      def self.interest_name(interest)
        "#{interest.data['title']} #{interest.data['bill_id']}"
      end
      
      # takes parsed response and returns an array where each item is 
      # a hash containing the id, title, and post date of each item found
      def self.items_for(response, function, options = {})
        raise AdapterParseException.new("Response didn't include results field: #{response.inspect}") unless response['bills']
        
        response['bills'].map do |bill|
          item_for bill
        end

        # if !(response['current_page'] = response['total_pages'])
        # url = response['links'][1]['href']

      end

      def self.item_detail_for(bill)
        item_for bill['bills'][0]
      end
      
      def self.item_for(bill)

        return nil unless bill

        # created_at and updated_at are UTC, take them directly as such
        ['creation_date', 'state' 'link_law'].each do |field|
          bill[field] = bill[field] ? bill[field].to_time : nil
        end

        if bill['events']
          bill['events'].each do |action|
            action['date'] = Time.zone.parse(action['date']) if action['date']
          end
        end

        if bill['urgencies']
          bill['urgencies'].each do |urgency|
            urgency['entry_date'] = Time.zone.parse(urgency['entry_date']) if urgency['entry_date']
          end
        end

          #puts "<bill>"
          #puts bill
          #puts "</bill>"

        SeenItem.new(
          item_id: bill["uid"],
          date: bill["creation_date"],
          data: bill
        )
      end

    end
  end
end