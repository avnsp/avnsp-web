require 'securerandom'
require 'sequel'

Sequel::Model.plugin :json_serializer

CF_DOMAIN = FQDN.freeze

class Member < Sequel::Model
  one_to_many :attendances
  one_to_many :transactions
  one_to_many :merits

  def full_name
    [first_name, nick && "\"#{nick}\"", last_name].compact.join " "
  end

  def parties
    attendances.map(&:party)
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
    transactions_dataset.sum(:sum)
  end
end

class Party < Sequel::Model
  one_to_many :attendances
  one_to_many :albums
  one_to_many :organizers

  def description
    "#{name}, #{date}"
  end

  def is_attending?(member_id)
    attendances.any? { |a| a.member_id == member_id }
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
