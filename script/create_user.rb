# Create a new user non-interactively.
# Can be invoked from the command line (see rails runner) to populate 
# users of a new installation. 

# FUNCTIONS

# Show script help
def show_help()
    puts 'Usage: rails runner create_user.rb <email> <password> <name> <admin>'
    puts 'The <admin> argument admits the values "true" and "false" (without quotes)'
end

# MAIN SCRIPT

# Check if asked for help
if ARGV[0]=='--help' || ARGV[0]=='-h'
    show_help()
    exit
end

# Check number of arguments
if ARGV.length != 4
    puts 'Wrong number of arguments'
    show_help()
    exit
end

email = ARGV[0]
password = ARGV[1]
name = ARGV[2]
admin_str = ARGV[3]

# Convert <admin> argument to boolean
admin_str = admin_str.strip.downcase
if admin_str == 'true'
    admin = true
elsif admin_str == 'false'
    admin = false
else
    puts 'Wrong usage: <admin> argument only admits "true" or "false" values'
    show_help()
    exit
end

# Check if email or username are already taken
if User.exists? email: email
    puts "Email #{email} has already been taken"
    exit
elsif User.exists? name: name
    puts "Name #{name} has already been taken"
    exit
end

# Disable sending signup confirmation email
Rails.application.config.action_mailer.delivery_method = :test

# Create new user
user = User.new email: email, password: password, name: name, admin: admin
user.save!
User.update confirmed_at: Time.zone.now
