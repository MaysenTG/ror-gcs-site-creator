# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Post.create(published: true, title: 'My first post', description: 'This is my great first post')
Post.create(published: false, title: 'My second post', description: 'This is my great second second post')
Post.create(published: true, title: 'My third post', description: 'This is my great third third third post')