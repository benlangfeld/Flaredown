class Checkin
  include Mongoid::Document

  HBI_PERIODICITY = 7

  #
  # Fields
  #
  field :date,        type: Date
  field :food_ids,    type: Array, default: []
  field :note,        type: String
  field :postal_code, type: String
  field :tag_ids,     type: Array
  field :weather_id,  type: Integer
  field :encrypted_user_id, type: String, encrypted: { type: :integer }

  #
  # Relations
  #
  has_one :harvey_bradshaw_index
  has_many :treatments, class_name: 'Checkin::Treatment'
  has_many :conditions, class_name: 'Checkin::Condition'
  has_many :symptoms, class_name: 'Checkin::Symptom'
  accepts_nested_attributes_for :conditions, :symptoms, :treatments, allow_destroy: true

  #
  # Indexes
  #
  index(encrypted_user_id: 1)
  index(date: 1, encrypted_user_id: 1)

  #
  # Validations
  #
  validates :encrypted_user_id, presence: true
  validates :date, presence: true, uniqueness: { scope: :encrypted_user_id }

  #
  # Scopes
  #
  scope :by_date, ->(startkey, endkey) { where(:date.gte => startkey, :date.lte => endkey) }

  def user
    @user ||= User.find(user_id)
  end

  def weather
    @weather ||= Weather.find_by(id: weather_id)
  end

  def tags
    @tags ||= Tag.where(id: tag_ids)
  end

  def foods
    @foods ||= Food.where(id: food_ids)
  end

  def available_for_hbi?
    return true if harvey_bradshaw_index
    return false unless date.today?
    return true unless latest_hbi

    HBI_PERIODICITY - ((latest_hbi.date)...date).count < 1
  end

  private

  def latest_hbi
    @_latest_hbi ||= HarveyBradshawIndex.where(encrypted_user_id: encrypted_user_id).order(date: :desc).first
  end
end
