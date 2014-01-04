class SentMail < ActiveRecord::Base
  attr_accessible :experiment_id, :from, :message, :message_type, :sender_id, :session_id, :subject, :to, :user_id
  belongs_to :user

  self.per_page = 30

  def message_type_to_string
  	I18n.t('mails.message_type'+message_type.to_s)
  end
end
