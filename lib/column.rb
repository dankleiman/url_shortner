# tracks column information
class Column
  
  attr_reader :column_name, :data_type
  
  # load the attributes from the database
  def initialize(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end
  
  # converts the value of this column to the correct ruby type
  def value_loader
    @data_type == 'integer' ? :to_i : :to_s
  end
  
end
