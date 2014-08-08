class CleanParams
  # @param [ActiveSupport::HashWithIndifferentAccess] params
  # @return [ActiveSupport::HashWithIndifferentAccess] Cleaned params
  def self.perform(params)
    cleaned_hash = ActiveSupport::HashWithIndifferentAccess.new
    params.each do |key, value|

      # convert all param keys to a snake case symbol
      new_key = key.to_s.underscore.to_sym

      if value.is_a?(Hash)
        cleaned_hash[new_key] = self.perform(value)
      else
        cleaned_hash[new_key] = value
      end

    end
    cleaned_hash
  end
end