module Subscriptions
  module Adapters

    class BillitsUrgencies

      def self.url_for(subscription, function, options = {})
        endpoint = "http://billit.ciudadanointeligente.org"

        item_id = subscription.interest_in

        url = "#{endpoint}/bills/search.json?"
        url << "uid=#{item_id}"

        url
      end

      def self.search_name(subscription)
        "Urgencies"
      end

      def self.short_name(number, interest)
        "#{number > 1 ? "urgencies" : "urgency"}"
      end

      def self.direct_item_url(urgency, interest)
        nil
      end

      def self.items_for(response, function, options = {})
        return nil unless response['bills'][0]['urgencies']

        events = []
        response['bills'][0]['urgencies'].each do |event|
          events << item_for(event['_id'], event)
        end
        events
      end


      # private

      def self.item_for(id, urgency)
        return nil unless urgency

        urgency['entry_date'] = Time.zone.parse urgency['entry_date']

        SeenItem.new(
          item_id: "#{id}-urgency-#{urgency['entry_date'].to_i}",
          date: urgency['entry_date'],
          data: urgency
        )
      end

    end

  end
end