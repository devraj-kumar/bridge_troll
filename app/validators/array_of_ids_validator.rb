# frozen_string_literal: true

class ArrayOfIdsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    unless value.respond_to?(:each)
      record.errors.add(attribute, 'must be an array')
      return
    end

    if value.empty?
      record.errors.add(attribute, 'must have at least one value')
      return
    end

    value.each do |id|
      record.errors.add(attribute, 'must be in the list') unless options[:in].include?(id)
    end
  end
end
