require 'helper'

class ImageTests < Minitest::Test
  def test_full_name
    image = Image.new('registry.example.org/project/image:123')

    assert_equal(image.registry, 'registry.example.org')
    assert_equal(image.namespace, 'project')
    assert_equal(image.name, 'image')
    assert_equal(image.tag, '123')
  end

  def test_empty_registry
    image = Image.new('project/image:123')

    assert(image.registry.nil?)
    assert_equal(image.namespace, 'project')
    assert_equal(image.name, 'image')
    assert_equal(image.tag, '123')
  end

  def test_multilevel_namespace
    image = Image.new('level1/project/image')

    assert(image.registry.nil?)
    assert_equal(image.namespace, 'level1/project')
    assert_equal(image.name, 'image')
  end

  def test_empty_namespace
    image = Image.new('image:123')

    assert(image.registry.nil?)
    assert(image.namespace.nil?)
    assert_equal(image.name, 'image')
  end

  def test_empty_tag
    image = Image.new('image')

    assert_equal(image.tag, 'latest')
  end

  def test_separate_tag
    image = Image.new('image', '123')

    assert(image.registry.nil?)
    assert(image.namespace.nil?)
    assert_equal(image.name, 'image')
    assert_equal(image.tag, '123')
  end

  def test_data
    image = Image.new('image', asset_id: 12)

    assert_equal(image.name, 'image')
    assert_equal(image.tag, 'latest')
    assert_equal(image.data[:asset_id], 12)
  end

  def test_normalized_name
    image = Image.new('registry.Example.org/pRoject/image:123')

    assert_equal(image.registry, 'registry.example.org')
    assert_equal(image.namespace, 'project')
    assert_equal(image.name, 'image')
    assert_equal(image.tag, '123')
  end

  def test_namespaced_name
    image = Image.new('registry.example.org/project/image:123')

    assert_equal(image.namespaced_name, 'project/image')
  end

  def test_namespaced_name_with_tag
    image = Image.new('registry.example.org/project/image:123')

    assert_equal(image.namespaced_name_with_tag, 'project/image:123')
  end

  def test_full_name_without_tag
    image = Image.new('registry.example.org/project/image:123')

    assert_equal(image.full_name_without_tag, 'registry.example.org/project/image')
  end

  def test_registry_with_port
    image = Image.new('registry.example.org:1234/project/image')

    assert_equal(image.registry, 'registry.example.org:1234')
    assert_equal(image.namespace, 'project')
    assert_equal(image.name, 'image')
    assert_equal(image.tag, 'latest')
  end
end
