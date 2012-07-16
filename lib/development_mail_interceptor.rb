class DevelopmentMailInterceptor
  def self.delivering_email(message)
    unless Rails.env.production?
      message.subject = "#{message.to} #{message.subject}"
      message.to = "hroottest@googlemail.com"
    end
  end
end