

class Field
  attr_accessor :name
  attr_accessor :options
  attr_accessor :values
  
  def initialize(name, options = {})
    @name = name.to_s
    @options = {}
    @options[:required] = options.fetch(:required, true)
    @options[:translate] = options.fetch(:translate, true)
    @options[:hint] = options.fetch(:hint, false)
    @options[:store_multiple] = options.fetch(:store_multiple, false)
    @options[:restrict_to_months] = options.fetch(:restrict_to_months, false)
    @options[:restrict_to_years] = options.fetch(:restrict_to_years, false)
    
    @options[:filter_operator] = options.fetch(:filter_operator, false)
    @options[:filter_search_multiple] = options.fetch(:filter_search_multiple, false)
    
    @options[:db_values] = options.fetch(:db_values, [])    
    @values = @options[:db_values]
  end
  
  def to_s
    @name
  end
  
  def display_value(user)
    user[name]
  end
  
  def add_validation(klass)
    if options[:required]
      field_name = name

      if options[:store_multiple]
        klass.class_eval do
          validates_each field_name do |record, attr, value|
            if (!value.blank? && value.kind_of?(Array) && value.reject{ |c| c.empty? }.length > 0)
              true
            else
              record.errors.add(attr, :blank)
            end
          end
        end
      else
        klass.class_eval do
          validates_presence_of field_name, :if => :validate_customfields?
        end
      end
    end  
  end
  
  def search_field
    SearchField.new(:name)
  end  
end

class SelectionField < Field
  
  def add_validation(klass)
    super(klass)    
    
    # add serialization for multiple selections
    if options[:store_multiple]
      field_name = name
      klass.class_eval do
        serialize field_name, ArraySerializer.new
      end
    end
  end
  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    if o[:translate]
      vals = values.map do |val|
        varname = if val.kind_of? Integer then "value"+val.to_s else val end
        [I18n.t('customfields.'+name+'.'+varname), val]
      end
    else
      vals = values
    end
    
    input_options = {:collection => vals, :required => false}
    input_options[:input_html] = {:include_blank => true, :multiple => true, :class => "chzn-select-register", :'data-placeholder' => " "} if o[:store_multiple]     
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    
    form.input name, input_options
  end
  
  def search_field
    if options[:translate]
      vals = values.map do |val|
        varname = if val.kind_of? Integer then "value"+val.to_s else val end
        [I18n.t('customfields.'+name+'.'+varname), val]
      end
    else
      vals = values
    end
    
    SelectionSearchField.new(name.to_sym, options.merge({:values => vals}))
  end  

  def display_value(user)
    # build hash of display values
    display_values = {}
    
    values.map do |v|
      varname = if v.kind_of? Integer then "value"+v.to_s else v end
      if options[:translate]
        display_values[v.to_s] = I18n.t('customfields.'+name+'.'+varname)
      else
        display_values[v.to_s] = v
      end
    end
    
    if options[:store_multiple]
      if user[name]
        user[name].map{|v| display_values[v.to_s]}.join(', ')
      else 
        puts "#{name} --> NIL--------------------"
      end
    else
      display_values[user[name].to_s]
    end    
  end
end  

class DateField < Field  
  def initialize(name, options = {})
    super(name, options)
  end
  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    input_options = {:required => false, :as => :string}
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    
    if o[:restrict_to_months]
      input_options[:input_html] = { :class => 'datepicker', :'data-date-format' => I18n.t('date.datepicker'), :'data-date-min-view-mode' => 1}
    elsif o[:restrict_to_years]
      input_options[:input_html] = { :class => 'datepicker', :'data-date-format' => I18n.t('date.datepicker'), :'data-date-min-view-mode' => 2}
    else  
      input_options[:input_html] = { :class => 'datepicker', :'data-date-format' => I18n.t('date.datepicker')}
    end
    
    form.input name, input_options
  end
  
  def search_field
    DateSearchField.new(name.to_sym)
  end  

end  

class TextField < Field  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    input_options = {:required => false}
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    form.input name, input_options
  end
end  


class CustomFieldManager  
  def initialize
    @fields = []
  end
  
  def self.setup(&block)
    instance = CustomFieldManager.new
    instance.instance_eval(&block) if block
    instance
  end

  def field_names_for_search
    @fields.select{|f| f.class.to_s != "TextField"}.map{|f| f.name.to_sym}
  end

  def fields
    @fields
  end
  
  def required
    @fields.select{|f| f.options[:required]}
  end
  
  def optional
    @fields.select{|f| !f.options[:required]}
  end
  
  def selection(name, options= {})
    @fields << SelectionField.new(name, options)
  end
  
  def date(name, options={})
    @fields << DateField.new(name, options)
  end
  
  def text(name, options={})
    @fields << TextField.new(name, options)
  end
  
  def boolean(name, options={})
    @fields << BooleanField.new(name, options)
  end
  
  def get(name)
    @fields.select{|f| f.name == name.to_s}.first
  end
    
  def setup_model(klass)
    fields.each do |f|
      klass.class_eval do
        attr_accessible f.name
      end
    end
    
    fields.each do |f|
      f.add_validation(klass)
    end
  end
end