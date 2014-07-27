class DevelopmentMailInterceptor
  def self.delivering_email(message)
    
    # in all environments other than production, do not send live emails
    # instead, the original to-field is added to the subject line, and the email
    # will be sent to an email adress configured in the environment
    
    unless Rails.env.production?
      # add original to.field to subject
      if Rails.configuration.respond_to?(:interceptor_subject_prefix) and not Rails.configuration.interceptor_subject_prefix.blank?
        message.subject = "#{Rails.configuration.interceptor_subject_prefix}#{message.subject} [original to: #{message.to}]"
      else
        message.subject = "#{message.to} #{message.subject}"
      end
      
      if Rails.configuration.respond_to?(:interceptor_email)
        # change recipient if configured
        message.to = Rails.configuration.interceptor_email
      else
        # or have no recipient at all (message fails then)
        message.to = ""
      end
    end
  end
end
