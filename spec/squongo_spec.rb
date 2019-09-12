RSpec.describe Squongo do
  it "has a version number" do
    expect(Squongo::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(true).to eq(true)
  end

  it 'can find by id' do
    class Post < Squongo::Document
      TABLE = :posts
    end

    Squongo.connect 'test.db'

    post = Post.find(1)
    binding.pry
  end

  it 'can find by key' do
    class Post < Squongo::Document
      TABLE = :posts
    end

    Squongo.connect 'test.db'
    # Squongo.start_writer

    # post = Post.new data: { title: 'foobar' }
    # post.save

    post = Post.find_by title: 'foobar'
    binding.pry
  end
end
