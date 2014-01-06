Sequel.migration do
  change do
    rename_table :events, :parties
    alter_table :photos do
      rename_column :event_id, :party_id
    end
    create_table :events do
      primary_key :id
      String :name
      DateTime :timestamp, default: Sequel.lit('NOW()')

      JSON :data
    end
  end
end
