Sequel.migration do
  change do
    create_table :members do
      primary_key :id
      String :first_name
      String :last_name
      String :nick
      String :studied
      Int :started
      String :email
      String :phone
      String :street
      Int :zip
      String :city
      String :password_hash
    end
  end
end
