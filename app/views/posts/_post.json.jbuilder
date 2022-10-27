json.extract! post, :id, :published, :title, :description, :created_at, :updated_at
json.url post_url(post, format: :json)
