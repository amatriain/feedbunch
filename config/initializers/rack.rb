# Use Rack::Deflater middleware to compress server responses when the client supports it.
Rails.application.config.middleware.use Rack::Deflater