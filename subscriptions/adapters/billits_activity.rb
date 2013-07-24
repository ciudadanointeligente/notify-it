module Subscriptions
  module Adapters

    class BillitsActivity

      def self.url_for(subscription, function, options = {})
        endpoint = "http://billit.ciudadanointeligente.org"

        item_id = subscription.interest_in

        url = "#{endpoint}/bills/search.json?"
        url << "uid=#{item_id}"

        url
      end

      def self.search_name(subscription)
        "Official Activity"
      end

      def self.short_name(number, interest)
        "#{number > 1 ? "events" : "event"}"
      end

      def self.direct_item_url(event, interest)
        nil
      end

      def self.items_for(response, function, options = {})
        return nil unless response['bills'][0]['events']

        events = []
        response['bills'][0]['events'].each do |event|
          events << item_for(event['_id'], event)
        end
        events
      end


      # private

      def self.item_for(id, event)
        return nil unless event

        event['date'] = Time.zone.parse event['date']

        SeenItem.new(
          item_id: "#{id}-event-#{event['date'].to_i}",
          date: event['date'],
          data: event
        )
      end

    end

  end
end