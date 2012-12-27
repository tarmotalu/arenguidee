# encoding: utf-8
class MakeEestiCategories < ActiveRecord::Migration
  def up
    Category.delete_all
    Category.create(:name => "Rahastamine", :description => 'Erakondade rahastamise ausus ja kontrollitavus, raha mõjuvõimu kahandamine poliitilises otsuseprotsessis.')
    Category.create(:name => "Konkurents", :description => 'Erakondadevahelise ja -sisese konkurentsi ausus ja elavus.')
    Category.create(:name => "Minu Hääl", :description => 'Valija hääle kaalukus valimistulemuse otsustamisel.')
    Category.create(:name => 'Kaasatus', :description => 'Kodanike aus kaasatus ja laialdasem osalemine poliitilises protsessis valimistevahelisel ajal.')
    Category.create(:name => 'Sunpolitseerimine', :description =>  'Ühiskondliku ruumi (sund)politiseerimise ja -parteistamise pidurdamine.')
    Category.create(:name => "Vaaria", :description => 'Teised teemad mis ei sobi viie teema alla')

  end

  def down
  end
end
