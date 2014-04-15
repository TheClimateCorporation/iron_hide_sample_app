require 'securerandom'
require 'minitest/autorun'
require 'iron_hide/storage/couchdb_adapter'
require 'iron_hide'
require 'vcr'
require 'webmock'
require 'minitest-vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
end
MinitestVcr::Spec.configure!

class User
  attr_accessor :friendly, :language
  attr_reader :id
  def initialize
    @id = SecureRandom.uuid
  end
end

Book = Struct.new(:owner, :author, :language)

module SharedExamples
  def self.included(base)

    describe "Authorization Rules" do
      before do
        @owner           = User.new
        @author          = User.new
        @author.language = :english
        @book            = Book.new(@owner, @author, :english)
      end

      it "allows owners to read their books" do
        IronHide.can?(@owner, :read, @book).must_equal true
      end

      it "disallows non-owners from read others' books" do
        IronHide.can?(User.new, :read, @book).must_equal false
      end

      it "allows authors to read their books" do
        IronHide.can?(@author, :read, @book).must_equal true
      end

      it "allows authors to write their books" do
        IronHide.can?(@author, :write, @book).must_equal true
      end

      it "allows authors to sell their books" do
        IronHide.can?(@author, :sell, @book).must_equal true
      end

      it "disallows authors from writing books in other languages" do
        russian_author          = User.new
        russian_author.language = :russian
        english_book            = Book.new(@owner,russian_author, :english)
        IronHide.can?(russian_author, :write, english_book).must_equal false
      end

      it "allows users to borrow books from other friendly users" do
        @owner.friendly = true
        another_user    = User.new
        IronHide.can?(another_user, :borrow_book, @owner).must_equal true
      end

      it "disallows users from borrowing books from other non-friendly users" do
        @owner.friendly = false
        another_user    = User.new
        IronHide.can?(another_user, :borrow_book, @owner).must_equal false
      end
    end
  end
end

describe "File Tests" do

  before do
    IronHide.config do |c|
      c.adapter   = :file
      c.json      = 'rules.json'
      c.namespace = 'TestApp'
    end
  end

  after { IronHide.reset }

  include  SharedExamples
end

describe "CouchDB Tests", :vcr do

  before do
    IronHide.config do |c|
      c.adapter   = :couchdb
      c.namespace = 'TestApp'
    end
  end

  after { IronHide.reset }

  include  SharedExamples
end
