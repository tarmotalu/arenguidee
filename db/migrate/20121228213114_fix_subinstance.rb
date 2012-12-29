class FixSubinstance < ActiveRecord::Migration
  def up
    si = SubInstance.first
    # si.name = 'Rahvakogu'
    # si.short_name = 'Rahvakogu'
    # si.default_locale = 'et'
    si.idea_name_max_length = 80
    si.save!
  end

  def down
  end
end
