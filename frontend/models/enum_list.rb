class EnumList
  require 'pry'
Pry::ColorPrinter.pp "we required the EnumList"
  @list = []
  @list_hash = {}
  @which = ''

  def initialize(which)
    @which = which
    renew
    Pry::ColorPrinter.pp "Initialized #{@which} #{@list.length}"
  end

  def value(label)
    if @list.index(label)
      v = label
    else
      v = @list_hash[label]
    end
    raise Exception.new(I18n.t('plugins.aspace-import-excel.error.enum',:label =>label,:which => @which)) if !v
    v
  end

  def length
    @list.length
  end

  def renew
    @list = []
    list_hash = {}
    enums =  JSONModel(:enumeration).all
    enums_list = ASUtils.jsonmodels_to_hashes(enums)
    enums_list.each do |enum|
      if enum['name'] == @which
        enum['values'].each do |v|
          if v
            list_hash[I18n.t("enumerations.#{@which}.#{v}", default: v)] = v
            @list.push v
          end
        end
        break
      end
    end
    @list_hash = list_hash
  end

end
