require 'forwardable'
require 'pg'

require './lib/column.rb'
require './lib/query_builder.rb'

class Model
  
  # build from the given attributes
  def initialize(attributes = {})
    self.attributes = attributes
  end
  
  # load the attributes into instance variables
  def attributes=(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end
  
  # true if this link is saved in the database
  def persisted?
    @persisted
  end
  
  # saves this link to the database
  def save
    columns = (self.class.columns_hash.values.map(&:column_name) - ['id'])
    values = columns.map { |column| self.send(column) }
    
    if self.persisted?
      query = columns.map.with_index(2) { |column, index| "#{column} = $#{index}" }.join(', ')
      self.class.connection.exec("UPDATE #{self.class.table_name} SET #{query} WHERE id = $1", [self.id] + values)
    else
      query = '(' + columns.join(', ') + ') VALUES '
      query << '(' + (1..columns.size).map { |index| "$#{index}" }.join(', ') + ')'
      self.class.connection.exec("INSERT INTO #{self.class.table_name} #{query}", values)
      @persisted = true
    end
  end
  
  # calls attributes= and then save
  def update_attributes(attributes)
    self.attributes = attributes
    self.save
  end
  
  class << self
    # forward a lot of methods to :all
    extend Forwardable
    def_delegators :all, :empty?, :first, :where
    
    attr_reader :connection, :table_name
    attr_writer :table_name
    
    # build a new query builder with a link to this class
    def all
      QueryBuilder.new(self)
    end
    
    # create the object from the given attributes, call save, and return the object
    def create(attributes)
      instance = self.new(attributes)
      instance.save
      instance
    end
    
    # a hash of information describing the columns in the database
    def columns_hash
      @columns_hash ||= begin
        columns_hash = {}
        @connection.exec("SELECT * FROM information_schema.columns WHERE table_name = '#{self.table_name}'").each do |result|
          column_name = result['column_name']
          columns_hash[column_name] = Column.new(result)
          attr_accessor column_name.to_sym
        end
        columns_hash
      end
    end
    
    # establish the connection to the database
    def establish_connection(db_config)
      @connection = PG::Connection.open(db_config)
    end
    
    # the name of the table for this model
    def table_name
      @table_name ||= (self.name.downcase + 's')
    end
  end
  
end
