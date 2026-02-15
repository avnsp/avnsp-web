# frozen_string_literal: true

require "bcrypt"
require "securerandom"
require "sequel"

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
    ds = Party.join(:attendances, party_id: :id)
      .where(Sequel[:attendances][:member_id] => self.id)
      .select_all(:parties)
      .order(Sequel[:parties][:date])
    ds = ds.where { Sequel[:parties][:date] < date } if date
    ds.all
  end

  def attendance(party_id)
    attendances_dataset.where(party_id: party_id).first || Attendance.new
  end

  def s3
    @s3_client ||= Aws::S3::Resource.new(region: "eu-west-1")
    @s3 ||= @s3_client.bucket("avnsp")
  end

  def profile_picture_cdn
    return unless profile_picture
    s3.object(profile_picture).presigned_url(:get, expires_in: 3600)
  end

  def thumb_cdn
    return unless profile_picture
    s3.object("#{profile_picture}.thumb").presigned_url(:get, expires_in: 3600)
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

  def attending?(member_id)
    attendances.any? { |a| a.member_id == member_id }
  end

  def purchases_highchart
    # Build lookup: {[article_name, member_id] => quantity}
    purchase_map = {}
    purchases_dataset.eager(:article).all.each do |p|
      purchase_map[[p.article.name, p.member_id]] = p.quantity
    end

    sorted_attendances = attendances_dataset.eager(:member).all.sort_by(&:nick)

    %w[Öl Snaps Cider Bastuöl Sångbok Läsk].map do |name|
      data = sorted_attendances.map { |a| purchase_map[[name, a.member_id]] || 0 }
      { id: name, name:, data: }
    end
  end
end

class Event < Sequel::Model
end

class Photo < Sequel::Model
  many_to_one :member
  one_to_many :comments, order_by: :timestamp, class: :PhotoComment

  def s3_path=(path)
    self.path = path + "/#{SecureRandom.uuid}.jpg"
    self.thumb_path = self.path.sub(".jpg", ".thumb.jpg")
    self.original_path = self.path.sub(".jpg", ".orig.jpg")
  end

  def s3
    @s3_client ||= Aws::S3::Resource.new(region: "eu-west-1")
    @s3 ||= @s3_client.bucket("avnsp")
  end

  def thumb_temp
    "https://#{CF_DOMAIN}/#{thumb_path}"
  end

  def file_temp
    "https://#{CF_DOMAIN}/#{path}"
  end

  def original_temp
    s3.object(original_path).presigned_url(:get, expires_in: 3600)
  end

  def surrounding_ids
    pk = self.id
    prev_id = Photo.where(Sequel.lit('id < ?', pk)).reverse_order(:id).get(:id)
    next_id = Photo.where(Sequel.lit('id > ?', pk)).order(:id).get(:id)
    [prev_id, next_id].compact
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
    [member.studied, member.started].join "-"
  end

  def member_previus_attendanceise
    type_pattern = party.type.include?("lunch") ? "%lunch%" : "%fest%"
    party_date = party.date
    Attendance.join(:parties, id: :party_id)
      .where(Sequel[:attendances][:member_id] => member_id)
      .where(Sequel.like(Sequel[:parties][:type], type_pattern))
      .where { Sequel[:parties][:date] < party_date }
      .count
  end

  def add_right_foot(right_foot)
    return unless right_foot
    return if right_foot[:name]&.empty? || right_foot["name"]&.empty?

    RightFoot.where(attendance_id: id).delete
    RightFoot.create(attendance_id: id,
                     name: right_foot["name"],
                     vegitarian: right_foot["vegitarian"] == "true",
                     non_alcoholic: right_foot["non_alcoholic"] == "true",
                     allergies: right_foot["allergies"])
  end
end

class Album < Sequel::Model
  many_to_one :party
  many_to_one :member, key: :created_by
  one_to_many :photos

  def party_name
    party&.name
  end

  def party_date
    party&.date
  end

  def title
    [name || party_name, date || party_date || timestamp.to_date].join(" - ")
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
