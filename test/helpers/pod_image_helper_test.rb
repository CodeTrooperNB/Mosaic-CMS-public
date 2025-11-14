require "test_helper"

class PodsImageHelperTest < ActionView::TestCase
  include PodImageHelper

  test "pod_image_url builds admin image attachment URL for key and variant" do
    data = { "hero_image" => { "attachment_key" => "hero_bg_001", "alt_text" => "Hero" } }
    url = pod_image_url(data, :hero_image, variant: "medium")
    assert_equal "/admin/image_attachments/hero_bg_001/medium", url

    original = pod_image_url(data, :hero_image, variant: "original")
    assert_equal "/admin/image_attachments/hero_bg_001/original", original
  end

  test "pod_image_url returns direct url when no attachment_key" do
    data = { "logo" => { "url" => "https://cdn.example.com/logo.png", "alt_text" => "Logo" } }
    url = pod_image_url(data, :logo, variant: "medium")
    assert_equal "https://cdn.example.com/logo.png", url
  end

  test "pod_image_tag renders img tag with alt from alt_text" do
    data = { "img" => { "attachment_key" => "key123", "alt_text" => "Alt Text" } }
    html = pod_image_tag(data, :img, variant: "thumbnail", class: "h-10 w-10")
    assert_includes html, "<img"
    assert_includes html, "alt=\"Alt Text\""
    assert_includes html, "/admin/image_attachments/key123/thumbnail"
  end
end
