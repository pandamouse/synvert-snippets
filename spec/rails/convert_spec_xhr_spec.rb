# encoding: utf-8

require 'spec_helper'

RSpec.describe 'Convert Spec XHR format' do
  before do
    rewriter_path = File.join(File.dirname(__FILE__), '../../lib/rails/convert_spec_xhr.rb')
    @rewriter = eval(File.read(rewriter_path))
  end

  def indent_content(content, count: 2)
    content.strip.split("\n").map { |line| line.empty? ? line : "#{' ' * count}#{line}" }.join("\n")
  end

  describe 'with fakefs', fakefs: true do
    let(:posts_controller_test_content) { '
class PostsControllerTest < ActionController::TestCase
  def test_show
    xhr :get, :show, { id: user.id }, { notice: "Welcome" }, { admin: user.admin? }
  end

  def test_index
    xhr :get, :index, params: { query: "test" }
  end

  def test_create
    xhr :post, :create, name: "user"
  end

  def test_destroy
    xhr :delete, :destroy, { id: user.id }, nil, { admin: user.admin? }
  end
end
    '.strip}
    let(:posts_controller_test_rewritten_content) { '
class PostsControllerTest < ActionController::TestCase
  def test_show
    get :show, xhr: true, params: { id: user.id }, flash: { notice: "Welcome" }, session: { admin: user.admin? }
  end

  def test_index
    get :index, xhr: true, params: { query: "test" }
  end

  def test_create
    post :create, xhr: true, params: { name: "user" }
  end

  def test_destroy
    delete :destroy, xhr: true, params: { id: user.id }, session: { admin: user.admin? }
  end
end
    '.strip}

    it 'converts', aggregate_failures: true do
      FileUtils.mkdir_p 'test/functional'
      File.write 'test/functional/posts_controller_test.rb', posts_controller_test_content
      @rewriter.process
      expect(File.read 'test/functional/posts_controller_test.rb').to eq posts_controller_test_rewritten_content
    end
  end
end
