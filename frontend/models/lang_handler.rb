class LangHandler < Handler
    @@language_types = EnumList.new('language_iso639_2')
    @@script_types = EnumList.new('script_iso15924')

    def self.renew
        clear(@@language_types)
        clear(@@script_types)
    end

    def self.create_language(row, substr,publish, report)
        langs = []
        have_lang = notes_keys.include?("n_lang#{substr}")
        have_note = notes_keys.include?("n_langmaterial#{substr}")
        if have_lang || have_note
          lang_val = have_lang ? row["n_lang#{substr}"] : row["n_langmaterial#{substr}"]
          begin
            lang_code = @@language_types.value(lang_val)
          rescue Exception => exception
            report.add_errors( I18n.t('plugins.aspace-import-excel.error.lang_code', :lang => lang_val))
            return langs  # stop right there!
          end
          langscript = JSONModel(:language_and_script).new
          langscript.language = lang_code
          if notes_keys.include?("n_langscript#{substr}")
            begin
              langscript.script = @@script_types.value(row["n_langscript#{substr}"])
            rescue => exception
                report.add_errors( I18n.t('plugins.aspace-import-excel.error.lang_code', :script => row["n_langscript#{substr}"]))
            end
          end
          lang = JSONModel(:lang_material).new
          lang.language_and_script = langscript
          langs.push lang
          
          if have_lang && have_note
            lang = JSONModel(:lang_material).new
            pub = row["p_langmaterial#{substr}"]
            pub = pub.blank? ? publish : (pub == '1')
            content = row["n_langmaterial#{substr}"]
            note = handle_one_note(content, {:value => 'langmaterial', :target => :note_langmaterial }, pub)
            lang.notes.push note
            langs.push lang
          end
          langs
        end   
    end
end