class User < ApplicationRecord
  acts_as_authentic do |c|
    c.login_field = :email
  end

  validates :username, presence: true, length: { minimum: 3, maximum: 25 }, uniqueness: true

  def deliver_password_reset_instructions!
    reset_perishable_token!
    PasswordResetMailer.reset_email(self).deliver_now
  end
end
