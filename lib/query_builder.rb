require 'forwardable'

class QueryBuilder
  
  # delegate many methods to query_results
  extend Forwardable
  def_delegators :query_results, :any?, :each, :empty?, :first
  
  # build a link to the class a hash of conditions
  def initialize(klass)
    @klass = klass
    @conditions = {}
  end
  
  # track the given conditions
  def where(conditions)
    selected_conditions = {}
    conditions.each do |key, value|
      if @klass.columns_hash.values.map(&:column_name).include?(key.to_s)
        selected_conditions[key.to_s] = value
      else
        raise ArgumentError, "Unknown column #{key}"
      end
    end
    @conditions.merge!(selected_conditions)
    self
  end
  
  private
  
  # build the query to be executed
  def query
    query = "SELECT * FROM #{@klass.table_name}"
    bind_variables = []
    
    if @conditions.any?
      query << ' WHERE '
      @conditions.each.with_index(1) do |(column_name, value), index|
        query << "#{column_name} = $#{index}"
        bind_variables << value
      end
    end
    
    [query, bind_variables]
  end
  
  # execute the query
  def query_results
    @klass.connection.exec(*query).map do |result|
      instance = @klass.new(persisted: true)
      result.each do |column_name, value|
        instance.send("#{column_name}=", value.send(@klass.columns_hash[column_name].value_loader))
      end
      instance
    end
  end
  
end
