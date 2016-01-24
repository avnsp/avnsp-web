Sequel.migration do
  change do
    create_table :photo_comments do
      primary_key :id

      Text :comment
      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :member_id, :members, null: false
      foreign_key :photo_id, :photos, null: false
    end
  end
end
