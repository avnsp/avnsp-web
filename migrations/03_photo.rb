Sequel.migration do
  change do
    create_table :photos do
      primary_key :id

      String :name
      String :caption
      String :path
      String :thumb_path
      String :original_path

      DateTime :taken_at
      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :member_id, :members, null: false
      foreign_key :event_id, :events
    end
  end
end
