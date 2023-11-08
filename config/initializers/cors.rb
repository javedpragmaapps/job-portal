Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'http://localhost:3000'
      resource '*',
               headers: :any,
               methods: [:get, :patch, :put, :delete, :post, :options, :show],
               expose: ['access-token', 'expiry', 'token-type', 'Authorization']
    end
  end