require_relative './models/post'

Squongo.connect('test.db')

RSpec.describe Squongo do
  it 'has a version number' do
    expect(Squongo::VERSION).not_to be nil
  end

  it 'creates a document' do
    document_object = { title: 'example', text: 'lorem ipsum' }
    post = Post.new(data: document_object)
    post.save
  end

  it 'can find by id' do
    document_object = { title: 'id test', text: 'lorem ipsum' }
    post = Post.new(data: document_object)
    post.save

    id = post.id

    expect(id).to eq Post.find(id).id
  end

  it 'can find by key' do
    document_object = { pages: [1, 2, 3] }

    post = Post.new(data: document_object)
    post.save

    # p = Post.find_by({ pages: [1] })
    p = Post.find_by({ pages: [1, 2, 3] })

    binding.pry
  end
end
