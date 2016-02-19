Sequel.migration do
  change do
    create_table 'purchases' do
      primary_key :id

      DateTime :timestamp, default: Sequel.lit('NOW()'), null: false
      Int :quantity, null: false, default: 0

      foreign_key :article_id, :articles, null: false
      foreign_key :member_id, :members, null: false
      foreign_key :party_id, :parties, null: false

      index [:article_id, :member_id, :party_id], unique: true
    end
  end
end
