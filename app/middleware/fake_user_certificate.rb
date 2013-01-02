class FakeUserCertificate
  def initialize(app)
    @app = app
  end
  
  # Add fake certificate for ID-card authentication
  def call(env)
    if env['PATH_INFO'] == '/users/auth/idcard'
      env['SSL_CLIENT_CERT'] = File.read(Rails.root.join('tmp', 'your_cert_file.cer'))
    end
    @app.call(env)
  end
end