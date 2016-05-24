class SitemapController < ApplicationController
  skip_after_action :verify_authorized

  def robots
    render file: 'sitemap/robots', layout: false, content_type: Mime::TEXT
  end

end
