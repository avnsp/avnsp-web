Sequel.migration do
  change do
    create_table :organizers do
      foreign_key :member_id, null: false
      foreign_key :party_id, null: false

      index [:member_id, :party_id]
    end
  end
end
