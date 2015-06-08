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
    haml :attend
  end

  post '/:id/attend' do |id|
    if attendance = Attendance.where(member_id: @member.id, party_id: id)
      attendance.update(vegitarian: params[:vegitarian] == 'true',
                        non_alcoholic: params[:non_alcoholic] == 'true',
                        allergies: params[:allergies])
      flash[:success] = "Din anmälan är ändrad"
      publish 'attendance.update', attendance.to_hash
    else
      attendance = Attendance.create(vegitarian: params[:vegitarian] == 'true',
                                       non_alcoholic: params[:non_alcoholic] == 'true',
                                       allergies: params[:allergies],
                                       member_id: @member.id,
                                       party_id: id)
      flash[:success] = "De är nu anmäld!"
      publish 'attendance.create', attendance.to_hash
    end
    redirect '/'
  end
  helpers do
    def name
      'party'
    end
  end
end
