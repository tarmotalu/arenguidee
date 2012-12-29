# -*- encoding : utf-8 -*-
Savon.configure do |savon|
  savon.logger = Logger.new('log/webservices.log')
  savon.raise_errors = false
end

Nori.advanced_typecasting = false
