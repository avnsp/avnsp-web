require 'bcrypt'
require 'securerandom'

class Member < Sequel::Model
  include BCrypt
  def password
    @password ||= Password.new(self.password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end
  def reset_password
    p = SecureRandom.urlsafe_base64(32 * 3/4)
    self.password = p
    self.save
    p
  end
end
class Event < Sequel::Model
end
