require 'active_support/concern'
module BawWorkers
  # Common functionality.
  module Common
    extend ActiveSupport::Concern

    private

    module ClassMethods

      def validate_contains(value, hash)
        fail ArgumentError, "Media type (#{value}) was not valid (#{hash})." unless hash.include?(value)

      end

      def validate_hash(hash)
        fail ArgumentError, "Media request params was not a hash (#{hash})" unless hash.is_a?(Hash)
      end

      def symbolize_hash_keys(hash)
        Hash[hash.map { |k, v| [k.to_sym, v] }]
      end

      def symbolize(value, hash)
        [value.to_sym, symbolize_hash_keys(hash)]
      end

      def check_datetime(value)
        # ensure datetime_with_offset is an ActiveSupport::TimeWithZone
        if value.is_a?(ActiveSupport::TimeWithZone)
          value
        else
          fail ArgumentError, 'Must provide a value for datetime_with_offset.' if value.blank?
          Time.zone.parse(value)
        end
      end

      # def self.stringify_hash(hash)
      #   s2s =
      #       lambda do |h|
      #         if Hash === h
      #           Hash[
      #               h.map do |k, v|
      #                 [
      #                     k.is_a?(Symbol) ? k.to_s : k,
      #                     s2s[v.is_a?(Symbol) ? v.to_s : v]
      #                 ]
      #               end
      #           ]
      #         elsif Array === h
      #           h.map { |item| item.is_a?(Symbol) ? item.to_s : item }
      #         else
      #           h
      #         end
      #       end
      #
      #   s2s[hash]
      # end

    end
  end
end