require './controllers/base'

class PartyController < BaseController
  get '/' do
    @parties = DB[:parties].order(:date).all
    haml :parties
  end

  get '/:id' do |id|
    @party = Party[id]
    @attendances = @party.attendances.sort_by(&:member_previus_attendanceise).reverse
    @albums = Album.where(party_id: id).all
    haml :party
  end

  get '/:id/attend' do |id|
    @attendance = @member.attendances.select { |a| a.party_id == id.to_i }.first
    @attendance ||= Attendance.new
    haml :attend_form, locals: { party_id: id, a: @attendance }
  end

  post '/:id/attend' do |id|
    if attendance = Attendance[member_id: @member.id, party_id: id]
      attendance.update(vegitarian: params[:vegitarian] == 'true',
                        non_alcoholic: params[:non_alcoholic] == 'true',
                        message: params[:message],
                        allergies: params[:allergies])
      publish 'attendance.update', attendance.to_hash
    else
      attendance = Attendance.create(vegitarian: params[:vegitarian] == 'true',
                                     non_alcoholic: params[:non_alcoholic] == 'true',
                                     allergies: params[:allergies],
                                     member_id: @member.id,
                                     message: params[:message],
                                     party_id: id)
      publish 'attendance.create', attendance.to_hash
    end
    redirect back
  end

  post '/:id/attend/delete' do |id|
    DB[:attendances].where(member_id: @member.id, party_id: id).delete
    redirect back
  end

  helpers do
    def name
      'party'
    end
  end
end
