Sequel.migration do
  change do
    create_table :photos do
      primary_key :id

      String :name
      String :caption
      String :path
      String :thumb_path
      String :original_path

      foreign_key :member_id, :members
      foreign_key :event_id, :events
    end
  end
end
