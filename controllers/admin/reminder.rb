require './controllers/admin/base'

class AdminReminderController < AdminBaseController
  get '/' do
    @members = members_with_negative_balance.map do |m|
      { full_name: m[:first_name], balance: m[:total] }
    end
    haml :send_reminder
  end

  post '/' do
    members_with_negative_balance.each do |member|
      nick = member[:nick] || ''
      full_name = "#{member[:first_name]} #{nick} #{member[:last_name]}"
      msg = {
        email: member[:email],
        name: full_name,
        balance: member[:total],
      }
      publish('member.reminder', msg)
    end
    redirect back
  end

  helpers do
    def admin_name
      'reminder'
    end

    def members_with_negative_balance
      DB["SELECT m.*, t.total
          FROM members m,
          (SELECT member_id, sum(sum) AS total FROM transactions GROUP BY member_id) t
          WHERE m.id = member_id AND total < 0 ORDER BY total"]
    end
  end
end
