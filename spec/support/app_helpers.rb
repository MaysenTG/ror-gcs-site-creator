module AppHelpers
  def ensure_plans!
    [
      { name: "Free", plan_handle: "free", max_sites: "3", max_site_size: "1", price: 0 },
      { name: "Enthusiast", plan_handle: "enthusiast", max_sites: "10", max_site_size: "10", price: 9 },
      { name: "Enterprise", plan_handle: "enterprise", max_sites: "100", max_site_size: "100", price: 49 }
    ].each do |attrs|
      plan = Plan.find_or_initialize_by(plan_handle: attrs[:plan_handle])
      plan.update!(attrs)
    end
    Plan.clear_plan_cache!
  end

  def storage_file(name:, content: "", size: nil, content_type: nil, updated_at: Time.current, media_url: nil)
    body = content.to_s
    file = instance_double(
      SiteStorage::ObjectMeta,
      name: name,
      size: size || body.bytesize,
      content_type: content_type,
      updated_at: updated_at,
      media_url: media_url || "https://cdn.example/#{name}"
    )
    allow(file).to receive(:download) { StringIO.new(body) }
    allow(file).to receive(:delete)
    allow(file).to receive(:copy)
    file
  end

  def stub_site_bucket(files: [], website_main: "index.html", website_404: "404.html")
    bucket = instance_double(SiteStorage::Bucket, website_main: website_main, website_404: website_404)
    allow(bucket).to receive(:files).and_return(files)
    allow(bucket).to receive(:file) do |key|
      files.find { |f| f.name == key }
    end
    allow(bucket).to receive(:create_file)
    allow(bucket).to receive(:exists?).and_return(true)
    allow(bucket).to receive(:delete)
    allow(bucket).to receive(:update) do |&block|
      config = Object.new
      def config.website_main=(*); end
      def config.website_404=(*); end
      block&.call(config)
    end
    bucket
  end

  def turbo_headers
    { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }
  end


  def stub_site_storage(bucket:)
    storage = instance_double(SiteStorage)
    allow(storage).to receive(:bucket).and_return(bucket)
    allow(storage).to receive(:create_bucket).and_return(bucket)
    allow(SiteStorage).to receive(:instance).and_return(storage)
    storage
  end
end

RSpec.configure do |config|
  config.include AppHelpers
  config.before(:suite) do
    # Plans are required for Account#current_plan limit checks.
    ActiveRecord::Base.connection_pool.with_connection do
      [
        { name: "Free", plan_handle: "free", max_sites: "3", max_site_size: "1", price: 0 },
        { name: "Enthusiast", plan_handle: "enthusiast", max_sites: "10", max_site_size: "10", price: 9 },
        { name: "Enterprise", plan_handle: "enterprise", max_sites: "100", max_site_size: "100", price: 49 }
      ].each do |attrs|
        plan = Plan.find_or_initialize_by(plan_handle: attrs[:plan_handle])
        plan.update!(attrs)
      end
      Plan.clear_plan_cache!
    end
  end
end
