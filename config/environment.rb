# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Hroot::Application.initialize!

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  attribute_name = instance.object.class.human_attribute_name instance.method_name
  if html_tag =~ /<(label)/
    html_tag
  else
    if instance.error_message.kind_of?(Array)  
      %(#{html_tag}<br/><span class="validation-error">#{attribute_name}
        #{instance.error_message.join(',')}</span>).html_safe
    else
      %(#{html_tag}<br/><span class="validation-error">#{attribute_name}
        #{instance.error_message}</span>).html_safe
    end
  end
end