# this is the base class for handling objects that  must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb

# One of the main differences is that we do lookups against the database for objects (such as agent, subject) that
# might already be in the database 

class Handler
  require 'enum_list'
  require 'pry'

  # centralize the checking for an already-found object
  def self.stored(hash, id, key)
    ret_obj = hash.fetch(id, nil) || hash.fetch(key, nil)
  end


  # returns nil, a hash of a jason model (if 1 found), or throws a multiples found error
  # if repo_id is nil, do a global search (subject and agent)
  # this is using   archivesspace/frontend/app/models/search.rb
  def self.search(repo_id,params,jmsym, *type)
    obj = nil
    search = nil
    if repo_id
      search  = Search.all(repo_id, params)
    else
      begin
        search = Search.global(params,type[0])
      rescue Exception => e
        s = JSONModel::HTTP::get_json("/search/#{type[0]}", params)
        raise e if !e.message.match('<h1>Not Found</h1>')  # global search doesn't handle this gracefully :-(
        search = {'total_hits' => 0}
      end
    end
    total_hits = search['total_hits'] || 0
#    Pry::ColorPrinter.pp "Total hits: #{total_hits}"
    if total_hits == 1 && !search['results'].blank? # for some reason, you get a hit of '1' but still have empty results??
      obj = JSONModel(jmsym).find_by_uri(search['results'][0]['id'])
    elsif  total_hits > 1
      raise Exception.new(I18n.t('plugins.aspace-import-excel.error.too_many'))
    elsif total_hits == 0
#      Pry::ColorPrinter.pp search
    end
    obj
  end

  def self.clear(enum_list)
    enum_list.renew
  end


end
