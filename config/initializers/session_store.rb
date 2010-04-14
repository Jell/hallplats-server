# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_poi_server_session',
  :secret => 'eda27fe97cd0ac2c8d79383b1fe0334c1c3572f41e4d395cf6469f0ac5c324d9a59d9ff4a82bfcb41905c59b6867d63abb379c9f20548ea437ec58a3b9784ae1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
