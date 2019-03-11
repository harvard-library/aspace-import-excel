module LinkedObjects
  extend ActiveSupport::Concern


# This module incorporates all the classes needed to handle objects that must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb



  #shamelessly stolen (and adapted from HM's nla_staff_spreadsheet plugin :-)
  class ParentTracker
    require 'pp'
    def set_uri(hier, uri)
      @current_hierarchy ||= {}
      @current_hierarchy = Hash[@current_hierarchy.map {|k, v|
                                  if k < hier
                                    [k, v]
                                  end
                                }.compact]

      # Record the URI of the current record
      @current_hierarchy[hier] = uri
    end
    def parent_for(hier)
      # Level 1 parent may  be a resource record and therefore nil, 
      if hier > 0
        parent_level = hier - 1
        @current_hierarchy.fetch(parent_level)
      else
        nil
      end
    end
  end #of ParentTracker

end
