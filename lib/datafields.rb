class Field
  attr_accessor :name
  attr_accessor :options
  
  def initialize(name, options = {})
    @name = name.to_s
    @options = options
    @options[:required] = options.fetch(:required, true)
    @options[:translation] = options.fetch(:translation, true)
    @options[:hint] = options.fetch(:hint, false)
    @options[:multiple] = options.fetch(:multiple, false)
    @options[:only_months] = options.fetch(:only_months, false)
  end
  
  def to_s
    @name
  end
  
  # todo we should be able to remove this in the end
  def search_field
    SearchField.new(:name)
  end
  
  def display_value(user)
    user[name]
  end
end

class SelectionField < Field
  attr_accessor :values
  attr_accessor :search_options
  
  def initialize(name, values, options = {}, search_options = {})
    super(name, options)
    @values = values
    @search_options = search_options
  end
  
  def sqltype
    "text"
  end
  
  def add_validation(klass)
    if options[:required]
      field_name = name
      klass.class_eval do
        validates_presence_of field_name
      end
    end  
    
    # add serialization for multiple selections
    if options[:multiple]
      field_name = name
      klass.class_eval do
        serialize field_name, ArraySerializer.new
      end
    end
  end
  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    if o[:translation]
      vals = values.map do |val|
        varname = if val.kind_of? Integer then "value"+val.to_s else val end
        [I18n.t('customfields.'+name+'.'+varname), val]
      end
    else
      vals = values
    end
    
    input_options = {:collection => vals, :required => false}
    input_options[:input_html] = {:include_blank => true, :multiple => true, :class => "chzn-select-register", :'data-placeholder' => " "} if o[:multiple]     
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    
    form.input name, input_options
  end
  
  def search_field
    if options[:translation]
      vals = values.map do |val|
        varname = if val.kind_of? Integer then "value"+val.to_s else val end
        [I18n.t('customfields.'+name+'.'+varname), val]
      end
    else
      vals = values
    end
    
    SelectionSearchField.new(name.to_sym, {:values => vals, :operator => search_options.fetch(:operator, false), :search_multiple => search_options.fetch(:search_multiple, false), :multiple => options[:multiple]})
  end  

  def display_value(user)
    # build hash of display values
    display_values = {}
    
    values.map do |v|
      varname = if v.kind_of? Integer then "value"+v.to_s else v end
      if options[:translation]
        display_values[v.to_s] = I18n.t('customfields.'+name+'.'+varname)
      else
        display_values[v.to_s] = v
      end
    end
    
    if options[:multiple]
      user[name].map{|v| display_values[v.to_s]}.join(', ')
    else
      display_values[user[name].to_s]
    end    
  end
end  

class DateField < Field  
  def initialize(name, options = {})
    super(name, options)
  end
  
  def sqltype
    "date"
  end
  
  def add_validation(klass)
    if options[:required]
      field_name = name
      klass.class_eval do
        validates_presence_of field_name
      end
    end  
  end
  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    input_options = {:required => false, :as => :string}
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    
    if o[:only_months]
      input_options[:input_html] = { :class => 'datepicker', :'data-date-format' => I18n.t('date.datepicker'), :'data-date-min-view-mode' => 1}
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
  def sqltype
    "varchar(255)"
  end
  
  def add_validation(klass)
    if options[:required]
      field_name = name
      klass.class_eval do
        validates_presence_of field_name
      end
    end  
  end
  
  def add_to_form(form, option_overrides={})
    o = options.merge(option_overrides)
    input_options = {:required => false}
    input_options[:hint] = I18n.t('hints.'+name) if o[:hint]
    form.input name, input_options
  end
end  


class Datafields
  @@fields = []
  
  def self.fields
    @@fields
  end
  
  def self.required
    @@fields.select{|f| f.options[:required]}
  end
  
  def self.optional
    @@fields.select{|f| !f.options[:required]}
  end
  
  def self.setup(&block)
    class_eval(&block) if block
  end
  
  def self.selection(name, values, options={}, search_options = {})
    @@fields << SelectionField.new(name, values, options, search_options)
  end
  
  def self.date(name, options={})
    @@fields << DateField.new(name, options)
  end
  
  def self.text(name, options={})
    @@fields << TextField.new(name, options)
  end
  
  def self.boolean(name, options={})
    @@fields << BooleanField.new(name, options)
  end
    
  def self.setup_model(klass)
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