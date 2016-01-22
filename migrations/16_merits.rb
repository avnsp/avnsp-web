Sequel.migration do
  change do
    create_table :merits do
      primary_key :id

      DateTime :start
      DateTime :end
      String :appointment

      foreign_key :member_id, :members, null: false
    end
  end
end
