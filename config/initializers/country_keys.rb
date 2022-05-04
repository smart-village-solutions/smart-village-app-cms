require 'csv'

COUNTRY_KEYS = CSV.parse(File.open(Rails.root.join('config', 'country_keys.csv')), :headers => false)
