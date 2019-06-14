module EtCcdExport
  module OptionalGenderHelper

    # Formats the gender correctly.  Valid values are Male, Female, N/K and nil - anything else will return nil
    # @param [String, Nil] gender The gender input - can either be a string or nil
    # @return [String, Nil] If nil was passed in, nil is returned - else the correct value for gender
    def optional_gender(gender)
      return gender if [nil, 'Male', 'Female', 'N/K'].include?(gender)
      nil
    end
  end
end
