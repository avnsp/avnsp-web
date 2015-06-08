require './controllers/base'

class MemberController < BaseController
  get '/:id' do |id|
    @member = Member[id]
    @parties = @member.parties.sort_by(&:date)
    haml :member
  end

  helpers do
    def name
      "Member"
    end
  end
end
