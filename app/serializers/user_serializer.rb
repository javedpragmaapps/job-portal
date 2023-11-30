class UserSerializer
  include JSONAPI::Serializer
  attributes :firstname, :lastname, :email, :id, :logged_in_at, :created_at, :city, :state, :mobile

  attributes :created_date do |user|
    user.created_at && user.created_at.strftime('%m/%d/%Y')
  end

  attributes :last_logged_at do |user|
    user.logged_in_at
  end
end
