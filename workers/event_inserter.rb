class EventWorker
  def start
    subscribe 'event.photo.create', 'photo.uploaded' do |_, data|
      DB.transaction do
        evt = { name: 'photo', data: data.to_json }
        id = DB[:events].insert(evt)
        publish 'event.photo.created', evt.merge(id: id)
      end
    end
    subscribe 'event.member.create', 'member.created' do |_, data|
      DB.transaction do
        evt = { name: 'member', data: data.to_json }
        id = DB[:events].insert(evt)
        publish 'event.member.created', evt.merge(id: id)
      end
    end
    subscribe 'event.party.create', 'party.created' do |_, data|
      DB.transaction do
        evt = { name: 'party', data: data.to_json }
        id = DB[:events].insert(evt)
        publish 'event.party.created', evt.merge(id: id)
      end
    end
  end

  def stop
  end
end
