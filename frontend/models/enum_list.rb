class EnumList
  require 'pry'
Pry::ColorPrinter.pp "we required the EnumList"
  @list = {}
  @which = ''

  def initialize(which)
    @which = which
    renew
    Pry::ColorPrinter.pp "Initialized #{@which} #{@list.length}"
  end

  def value(label)
    v = @list[label]
    raise Exception.new("'#{label}' not found in list #{@which}") if !v
    v
  end

  def length
    @list.length
  end

  private
  def renew
    list = {}
    enums =  JSONModel(:enumeration).all
    enums_list = ASUtils.jsonmodels_to_hashes(enums)
    enums_list.each do |enum|
      if enum['name'] == @which
        enum['values'].each do |v|
          if v
            list[I18n.t("enumerations.#{@which}.#{v}", default: v)] = v
          end
        end
        break
      end
    end
    @list = list
  end

end
