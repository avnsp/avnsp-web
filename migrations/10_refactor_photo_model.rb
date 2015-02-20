Sequel.migration do
  change do
    create_table :albums do
      primary_key :id

      String :name

      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :create_by, :members, null: false
      foreign_key :party_id, :parties
    end

    alter_table :members do
      add_column :profile_picture, :text
    end

    alter_table :photos do
      add_foreign_key :album_id, :albums
      drop_foreign_key :party_id
      drop_foreign_key :member_id
    end
  end
end

