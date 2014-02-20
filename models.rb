require 'bcrypt'
require 'securerandom'
require 'sequel'

Sequel::Model.plugin :json_serializer

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

class Party < Sequel::Model
  one_to_many :photos
end

class Event < Sequel::Model
end

class Photo < Sequel::Model
  many_to_one :photo
  many_to_one :member
  def s3_path= path
    self.path = path + "/#{SecureRandom.uuid}.jpg"
    self.thumb_path = self.path.sub('.jpg', '.thumb.jpg')
    self.original_path = self.path.sub('.jpg', '.orig.jpg')
  end
  def s3
    s3 = AWS::S3.new
    @objects ||= s3.buckets['avnsp'].objects
  end
  def thumb_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.thumb_path}"
  end
  def file_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.path}"
  end
  def original_temp
    "https://d18qrfc4r3cv12.cloudfront.net/#{self.original_path}"
  end
end
