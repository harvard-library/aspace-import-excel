class LangHandler < Handler
    @@language_types = EnumList.new('language_iso639_2')
    @@script_types = EnumList.new('script_iso15924')

    def self.renew
        clear(@@language_types)
        clear(@@script_types)
    end

    # special method to determine if we can deal with language blocks
    def self.ead3
      return @@language_types.length > 0
    end

    def self.create_language(row, substr,publish, report)
      langs = []
      have_lang = !row["l_lang#{substr}"].blank?
      have_note = !row["n_langmaterial#{substr}"].blank?
      if have_lang || have_note
        lang_code = nil
        if !have_lang
          begin
            lang_code = @@language_types.value(row["n_langmaterial#{substr}"])
            have_note = false
            row["n_langmaterial#{substr}"] = nil
          rescue Exception => n
            #we know that the note isn't just the language
          end
        else
          begin
            lang_code = @@language_types.value(row["l_lang#{substr}"])
          rescue Exception => n
            report.add_errors( I18n.t('plugins.aspace-import-excel.error.lang_code', :lang => row["l_lang#{substr}"]))
          end
        end
        if lang_code
          langscript = JSONModel(:language_and_script).new
          langscript.language = lang_code
          if !row["l_langscript#{substr}"].blank?
            begin
              langscript.script = @@script_types.value(row["l_langscript#{substr}"])
            rescue Exception => n
              report.add_errors( I18n.t('plugins.aspace-import-excel.error.script_code', :script => row["l_langscript#{substr}"]))
            end
          end
          lang = JSONModel(:lang_material).new
          lang.language_and_script = langscript
          langs.push lang
        end        
        if have_note
          lang = JSONModel(:lang_material).new
          pub = row["p_langmaterial#{substr}"]
          pub = pub.blank? ? publish : (pub == '1')
          content = row["n_langmaterial#{substr}"]
          begin
            wellformed(content)
            note = JSONModel(:note_langmaterial).new
            note.publish = publish
            note.type = 'langmaterial'
            note.content.push content if !content.nil?
            lang.notes.push note
            langs.push lang 
          rescue Exception => e
            report.add_errors(I18n.t('plugins.aspace-import-excel.error.bad_note', :type => 'langmaterial' , :msg => CGI::escapeHTML( e.message)))
          end
          row["n_langmaterial#{substr}"] = nil                       
        end
      end
      langs 
    end
    # currently a repeat from the controller
    def self.wellformed(note)
      if note.match("</?[a-zA-Z]+>")
        frag = Nokogiri::XML("<root xmlns:xlink='https://www.w3.org/1999/xlink'>#{note}</root>") {|config| config.strict}
      end
    end
end