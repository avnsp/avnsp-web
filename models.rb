require 'bcrypt'
require 'securerandom'
require 'sequel'

Sequel::Model.plugin :json_serializer

CF_DOMAIN = FQDN.freeze

class Member < Sequel::Model
  one_to_many :attendances
  one_to_many :transactions, order: :timestamp
  one_to_many :merits
  one_to_many :purchases

  def purchases(id)
    purchases_dataset.where(party_id: id)
  end

  def full_name
    [first_name, nick && "\"#{nick}\"", last_name].compact.join " "
  end

  def parties(date = nil)
    parties = attendances.map(&:party)
    parties = parties.select { |p| p.date < date } if date
    parties.sort_by(&:date)
  end

  def attendance(party_id)
    attendances.find { |a| a.party_id == party_id } || Attendance.new
  end

  def profile_picture_cdn
    "https://#{CF_DOMAIN}/#{self.profile_picture}"
  end

  def thumb_cdn
    "https://#{CF_DOMAIN}/#{self.profile_picture}.thumb"
  end

  def balance
    transactions_dataset.sum(:sum) || 0
  end

  include BCrypt
  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end
end

class Party < Sequel::Model
  one_to_many :attendances
  one_to_many :albums
  one_to_many :organizers
  one_to_many :purchases

  def description
    "#{name}, #{date}"
  end

  def is_attending?(member_id)
    attendances.any? { |a| a.member_id == member_id }
  end

  def purchases_highchart
    %w(Öl Snaps Cider Bastuöl Sångbok Läsk).map do |name|
      data = attendances.sort_by(&:nick).map do |a|
        p = purchases.find { |p| p.name == name && p.member_id == a.member_id }
        p&.quantity || 0
      end
      {
        id: name,
        name: name,
        data: data.flatten,
      }
    end
  end
end

class Event < Sequel::Model
end

class Photo < Sequel::Model
  many_to_one :member
  one_to_many :comments, order_by: :timestamp, class: :PhotoComment

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
    "https://#{CF_DOMAIN}/#{self.thumb_path}"
  end

  def file_temp
    "https://#{CF_DOMAIN}/#{self.path}"
  end

  def original_temp
    "https://#{CF_DOMAIN}/#{self.original_path}"
  end
  
  def surrounding_ids
    rows = Photo.dataset.order_by(:id).all
    i = rows.index { |r| r[:id] == id }
    rows[(i - 1)..(i + 1)].select { |r| r[:id] != id }.map(&:id)
  end
end

class Attendance < Sequel::Model
  many_to_one :member
  many_to_one :party
  one_to_many :right_feet, class: :RightFoot

  def right_foot
    right_feet.first
  end

  def nick
    member.nick || member.first_name
  end

  def member_name
    member.full_name
  end

  def member_studied_started
    [member.studied, member.started].join '-'
  end

  def member_previus_attendanceise
    attendances = member.attendances
    type = party.type.include?('lunch') ? 'lunch' : 'fest'
    attendances.select do |a|
      a.party.type.include?(type) && a.party.date < party.date
    end.count
  end

  def add_right_foot(right_foot)
    RightFoot.where(attendance_id: id).delete
    RightFoot.create(attendance_id: id,
                     name: right_foot['name'],
                     vegitarian: right_foot['vegitarian'] == 'true',
                     non_alcoholic: right_foot['non_alcoholic'] == 'true',
                     allergies: right_foot['allergies'])
  end
end

class Album < Sequel::Model
  many_to_one :party
  many_to_one :member, key: :created_by
  one_to_many :photos

  def party_name
    party && party.name
  end

  def party_date
    party && party.date
  end

  def title
    [name || party_name, date || party_date || timestamp.to_date].join(' - ')
  end

  def description
    text
  end
end

class Transaction < Sequel::Model
end

class Merit < Sequel::Model
end

class PhotoComment < Sequel::Model
  many_to_one :member
end

class Organizer < Sequel::Model
  many_to_one :member
  many_to_one :party
end

class Purchase < Sequel::Model
  many_to_one :article
  many_to_one :party
  many_to_one :member

  def name
    article.name
  end
end

class Article < Sequel::Model
end

class RightFoot < Sequel::Model(:right_feet)
  many_to_one :attendance
end

