ConsiderIt::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.eager_load = true
   
  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :mem_cache_store, { :expires_in => 1.day, :compress => true }

  config.force_ssl = false

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_files = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "//#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net"


  config.active_job.queue_adapter = :delayed_job

  # Enable S3/Cloudfront storage for Paperclip
  #Paperclip::Attachment.default_options.merge!({
  #  :path => "system/:attachment/:id/:style/:filename",
  #  :url => ":s3_alias_url",   
  #  :default_url => "system/default_avatar/:style_default-profile-pic.png",
  #  :storage => :s3,
  #  :bucket => APP_CONFIG[:aws][:s3_bucket],
  #  :s3_host_alias => "#{APP_CONFIG[:aws][:cloudfront]}.cloudfront.net",
  #  :s3_protocol => "https",
  #  :s3_headers => {'Expires' => 1.year.from_now.httpdate},
  #  :s3_credentials => {
  #    :access_key_id => APP_CONFIG[:aws][:access_key_id],
  #    :secret_access_key => APP_CONFIG[:aws][:secret_access_key]
  #  }
  #})

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true
  # config.action_mailer.default_url_options = { :address => 'localhost' }
  config.action_mailer.perform_deliveries = true 

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.middleware.use Rack::Prerender
  
  # Exception Notification
  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[ConsiderIt Error] ",
      :sender_address => '"Notifier" ',
      :exception_recipients => ['you@yourdomain.com']
    }

end
