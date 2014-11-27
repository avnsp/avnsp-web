Sequel.migration do
  change do
    create_table :booking_accounts do
      Int :number, primary_key: true
      String :name
    end

    create_table :articles do
      primary_key :id

      String :name

      foreign_key :booking_account_number, :booking_accounts
    end

    create_table :parties_articles do
      Float :price

      foreign_key :article_id, :articles
      foreign_key :party_id, :parties

      index [:article_id, :party_id]
    end

    create_table :transactions do
      primary_key :id

      Float :sum
      Text :text
      DateTime :timestamp, default: Sequel.lit('NOW()')

      foreign_key :party_id, :parties
      foreign_key :article_id, :articles

      foreign_key :member_id, :members, null: false
      foreign_key :booking_account_number, :booking_accounts, null: false
    end

    alter_table :parties do
      add_foreign_key :booking_account_number, :booking_accounts, null: false
    end
  end
end
