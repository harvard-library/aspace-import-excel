# this is the base class for handling objects that  must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb

# One of the main differences is that we do lookups against the database for objects (such as agent, subject) that
# might already be in the database 

class Handler
  require 'enum_list'
  require 'pry'

  # returns nil, a hash of a jason model (if 1 found), or throws a multiples found error
  def self.search(repo_id,params,jmsym)
    obj = nil
    search  = Search.all(repo_id, params)
    total_hits = search['total_hits'] || 0
#    Pry::ColorPrinter.pp "Total hits: #{total_hits}"
    if total_hits == 1 && !search['results'].blank? # for some reason, you get a hit of '1' but still have empty results??
      obj = JSONModel(jmsym).find_by_uri(search['results'][0]['id'])
    elsif  total_hits > 1
      raise Exception.new("Too many")
    elsif total_hits == 0
#      Pry::ColorPrinter.pp search
    end
    obj
  end

  def self.clear(enum_list, obj_list)
    enum_list.renew
    obj_list = {} if obj_list
  end


end
