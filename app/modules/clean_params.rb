# frozen_string_literal: true

class CleanParams
  # get a cleaned Hash
  # @param [Hash] hash_to_clean
  # @return [Hash] Cleaned hash
  def self.hash(hash_to_clean)
    cleaned_hash = {}
    hash_to_clean.each do |key, value|
      # convert all param keys to a snake case symbol
      new_key = clean(key)

      cleaned_hash[new_key] = perform(value)
    end
    cleaned_hash
  end

  # get a cleaned Array
  # @param [Array] array_to_clean
  # @return [Array] Cleaned array
  def self.array(array_to_clean)
    cleaned_array = []
    array_to_clean.each do |item|
      cleaned_array.push perform(item)
    end
    cleaned_array
  end

  # get a cleaned object
  # @param [Object] to_clean
  # @return [Object] Cleaned object
  def self.perform(to_clean)
    if to_clean.is_a?(Hash)
      hash(to_clean)
    elsif to_clean.is_a?(Array)
      array(to_clean)
    else
      to_clean
    end
  end

  def self.clean(value)
    value.to_s.underscore.to_sym
  end
end
