class Emote < ActiveRecord::Base
  validates :text, presence: true, uniqueness: true

  # Make sure the text numerics are assigned properly
  after_create :assign_text_numeric_vals
  before_save  :assign_text_numeric_vals

  scope :all_tags, -> (tags) { where('tags @> ARRAY[?]', tags) }
  scope :any_tags, -> (tags) { where('tags && ARRAY[?]', tags) }

  def text=(text)
    super
    assign_text_numeric_vals
  end

  private

  def assign_text_numeric_vals
    self.text_rows           = calc_text_rows(text)
    self.longest_line_length = calc_longest_line_length(text)
  end

  def calc_longest_line_length(text)
    return nil if text.nil?
    lines = text.lines.map(&:chomp)
    lines.collect{ |l| l.length }.max
  end

  def calc_text_rows(text)
    return nil if text.nil?
    text.lines.map(&:chomp).count
  end
end
