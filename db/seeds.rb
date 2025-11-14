# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

# Create default admin user
admin_user = AdminUser.find_or_create_by(email: 'admin@pcdmosaic.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Admin'
  user.last_name = 'User'
  user.role = 'admin'
end

puts "Created admin user: #{admin_user.email}" if admin_user.persisted?

# Create default editor user
editor_user = AdminUser.find_or_create_by(email: 'editor@pcdmosaic.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'Editor'
  user.last_name = 'User'
  user.role = 'editor'
end

puts "Created editor user: #{editor_user.email}" if editor_user.persisted?