require './customizations'


window.translation_progress = (lang, key_prefix) -> 
  key_prefix ||= '/translations'
  translations = fetch "#{key_prefix}/#{lang}"
  dev_language = fetch "#{key_prefix}/en"

  messages =   (k for k,v of dev_language when v.txt?.length > 0 or v.proposals?[0]?.txt?.length > 0)
  translated = (k for k,v of translations when v.txt?.length > 0 or v.proposals?[0]?.txt?.length > 0)

  translated.length / messages.length



regexp_tsplit = /<(\w+)>[^<]+<\/[\w|\s]+>/g
regexp_tmatch = /<(\w+)>([^<]+)<\/[\w|\s]+>/g
window.TRANSLATE = (args, native_text) -> 

  if typeof args == "string"
    native_text = args 
    args = {}

  tr = fetch 'translations'

  args.return_lang_used = true
  {message, lang_used, target_lang} = T args, native_text 


  # allow composing of components into translatable messages
  if message.indexOf('<') > -1
    parts = message.split(regexp_tsplit)
    matches = {}


    while match = regexp_tmatch.exec(message)
      matches[match[1]] = match[2]

    translation = []
    for part in parts 
      if part of matches && part of args 
        def = args[part]
        translation.push def.component(def.args, matches[part])
      else 
        translation.push part 

    translation
  else 
    translation = message

  if !tr.in_situ_translations
    translation 
  else 
    IN_SITU_TRANSLATOR _.extend({lang_used, target_lang, message, native_text}, args), translation

IN_SITU_TRANSLATOR = ReactiveComponent
  displayName: 'InSituTranslator'
  render: ->
    key = @props.key or '/translations'
    target_lang = @props.target_lang

    translated = @props.lang_used == target_lang
    id = @props.id or @props.native_text
    available_languages = fetch('/translations').available_languages
    SPAN 
      style: 
        backgroundColor: if translated then "rgba(166, 195, 151, .5)" else "rgba(251,124,124,.5)"
        position: 'relative'
      onMouseOver: =>
        @local.show_translator = true 
        save @local

      @props.children

      if @local.show_translator
        updated_translations = get_temporary_translations target_lang, key
        message_style = 
          fontWeight: 700

        DIV 
          style: 
            position: 'absolute'
            zIndex: 9999
            fontSize: 14
            width: 300
            padding: '4px 8px'
            backgroundColor: 'white'
            border: "1px solid #ccc"

          DIV 
            style: {}
            "English message: "
            DIV 
              style: message_style
              "#{@props.native_text}"

          DIV 
            style: 
              marginTop: 8
            LABEL null, 
              "#{available_languages[target_lang]} translation:"

            editable_translation id, updated_translations, message_style


          BUTTON 
            className: "primary_button"
            style: 
              backgroundColor: focus_color()
              fontSize: 14
            onClick: => 
              promote_temporary_translations(target_lang, key)
              @local.show_translator = false 
              save @local 

            "Save" 

          BUTTON 
            style: 
              backgroundColor: 'none'
              border: 'none'
              color: '#888'

            onClick: => 
              @local.show_translator = false 
              save @local 
            "Cancel" 

              




DEVELOPMENT_LANGUAGE = 'en'

window.T = window.t = (args, native_text) -> 
  # user = fetch '/current_user'
  subdomain = fetch '/subdomain'

  if typeof args == "string"
    native_text = args 
    args = {}


  id = args.id or native_text
  translations_key_prefix = args.key or "/translations"

  translations_native = fetch "#{translations_key_prefix}/#{DEVELOPMENT_LANGUAGE}"

  return '...' if waiting_for(translations_native)


  # ensure this string is in the translations database for the development language
  if translations_native[id]?.txt != native_text
    translations_native[id] ||= {}
    translations_native[id].txt = native_text
    save translations_native  

  # which language should we use? ordered by preference. 
  # user = fetch '/current_user'
  user = {}
  langs = [user.lang, subdomain.lang, DEVELOPMENT_LANGUAGE].filter((l) -> l?)
  langs = Array.from(new Set(langs)) if langs.length > 1

  # find the best language translation we have
  lang_used = null 
  message = null 
  for lang in langs
    translations = fetch "#{translations_key_prefix}/#{lang}"
    if translations[id]?
      message = translations[id].txt
      # if this user has proposed one, use that
      if translations[id].proposals?.length > 0
        u = fetch('/current_user').user
        for proposal in translations[id].proposals
          if proposal.u == u 
            console.log u, proposal.u
            message = proposal.txt 
      if message
        lang_used = lang 
        break 

  translator = new IntlMessageFormat.IntlMessageFormat message, lang_used
  message = translator.format(args)

  if args.return_lang_used # useful for a T wrapper that enables in situ translations
    {message, lang_used, target_lang: langs[0]}
  else 
    message


TranslationsDash = ReactiveComponent
  displayName: 'TranslationsDash'

  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    translations = fetch '/translations'

    return DIV() if !translations.available_languages

    local = fetch 'translations'

    all_langs = ( [k,v] for k,v of translations.available_languages when k != DEVELOPMENT_LANGUAGE)

    if !local.translating_lang
      if subdomain.lang && subdomain.lang != 'en'
        local.translating_lang = subdomain.lang 
      else 
        local.translating_lang = all_langs[0][0]

    DIV null, 

      DashHeader name: 'Translations'

      DIV style: {width: HOMEPAGE_WIDTH(), margin: '0px auto'},

        DIV style: {},
          "ConsiderIt's native development language is English (en). Please help us translate it to your language!"

        DIV 
          style: 
            marginTop: 24

          "Which language do you wish to translate for?"


          SELECT 
            value: local.translating_lang
            style: 
              fontSize: 20
              marginLeft: 14
              display: 'inline-block'
            onChange: (ev) => 
              local.translating_lang = ev.target.value 
              save local

            for [k,v] in all_langs
              OPTION 
                value: k
                "#{v} (#{k})"

          DIV 
            style: 
              fontSize: 12
            "Is your language not available? Email us at hello@consider.it to get your language added."


        DIV 
          style: 
            marginTop: 24

          LABEL 
            htmlFor: 'insitutranslations'
            "Enable in-situ translations?"

          INPUT 
            id: 'insitutranslations'
            type: 'checkbox' 
            checked: fetch('translations').in_situ_translations
            style: 
              fontSize: 36
            onChange: => 
              tr = fetch 'translations'
              tr.in_situ_translations = !tr.in_situ_translations
              save tr 


          DIV 
            style: 
              fontSize: 12
            "In-situ mode lets you browse the rest of the site and add translations in context."


        if current_user.is_super_admin
          DIV 
            style: 
              marginTop: 24

            "Add a new language"

            DIV null,

              INPUT 
                style: 
                  fontSize: 18
                type: 'text'
                ref: 'newlang_abbrev'
                placeholder: 'Abbreviation'

              INPUT               
                type: 'text'
                ref: 'newlang_label'
                placeholder: 'Full Name'
                style: 
                  margin: '0 8px'
                  fontSize: 18

              BUTTON
                onClick: => 
                  abbrev = @refs.newlang_abbrev.getDOMNode().value
                  label = @refs.newlang_label.getDOMNode().value

                  if abbrev not of translations.available_languages
                    translations.available_languages[abbrev] = label 
                    save translations

                    @refs.newlang_abbrev.getDOMNode().value = ""
                    @refs.newlang_label.getDOMNode().value = ""

                "Add"


        if local.translating_lang
          DIV null, 

            TranslationsForLang
              key: "/translations"
              lang: local.translating_lang

            # if current_user.is_admin 
            TranslationsForLang
              key: "/translations/#{subdomain.name}"
              lang: local.translating_lang



TranslationsForLang = ReactiveComponent
  displayName: 'TranslationsForLang'

  render: ->

    lang = @props.lang 

    available_languages = fetch("/translations").available_languages
    native_messages = fetch "#{@props.key}/#{DEVELOPMENT_LANGUAGE}"
    translations = fetch "#{@props.key}/#{lang}"

    return DIV() if waiting_for(native_messages) || waiting_for(translations)

    to_translate = (k for k,v of native_messages when k != 'key')
    return DIV() if to_translate.length == 0 

    # create local copy of proposed translations before saving
    # TODO: I think this is making a shallow clone, which means that updated_translations and translations might 
    #       point to the same {txt, proposals} objects. 
    updated_translations = get_temporary_translations(lang, @props.key)


    sections = {}
    for name in to_translate
      sp = name.split('.')
      if sp.length > 1
        sections[sp[0]] ||= []
        sections[sp[0]].push name
      else 
        sections.misc ||= []
        sections.misc.push name

    current_user = fetch '/current_user'

    DIV 
      style: 
        marginTop: 36

      H2 
        style: 
          fontSize: 22

        T 
          id: "i18n.language_header"
          percent_complete: Math.round(translation_progress(lang, @props.key) * 100)
          language: available_languages[lang]
          "Translations for {language} ({percent_complete}% completed)"


      TABLE 
        style: 
          width: HOMEPAGE_WIDTH()

        TR 
          style: 
            backgroundColor: '#dfdfdf'


          for col in ['Message ID', 'Message in English', "Translation to #{available_languages[lang]}"]
            TH
              style: 
                textAlign: 'left'
                padding: "4px 6px"
              col


        for section, names of sections

          for name in names
            do (name) => 
              no_id = name == native_messages[name].txt
              TR 
                style: {}

                TD 
                  style:
                    width: "24%"
                    padding: "2px 4px"
                    # display: 'inline-block'
                    # verticalAlign: 'top'
                    # fontStyle: 'italic' if no_id
                    # color: "#888" if no_id

                  if !no_id 
                    name 
                  else 
                    'no id'

                TD 
                  style: 
                    padding: "2px 4px"
                    width: "37%"
                    # display: 'inline-block'
                    # verticalAlign: 'top'

                  "#{native_messages[name].txt}"

                TD  
                  style: 
                    width: '39%'
                    padding: "2px 4px"

                  # width: "42%"
                  # display: 'inline-block'
                  # verticalAlign: 'top'


                  editable_translation name, updated_translations

                  if current_user.is_super_admin && updated_translations[name]?.proposals
                    UL  
                      style: {}

                      for proposal, idx in updated_translations[name].proposals
                        do (proposal, name, idx) =>
                          LI 
                            style: 
                              padding: "2px 0px 8px 0px"
                              listStyle: 'none'

                            DIV 
                              style: {}
                              proposal.txt 

                            SPAN 
                              style: 
                                fontSize: 14
                                color: "#aaa"
                                paddingRight: 4
                              "by #{current_user.name or current_user.user}"

                            BUTTON
                              style: 
                                borderRadius: 8
                              onClick: => 
                                updated_translations[name].txt = proposal.txt 
                                updated_translations[name].u = proposal.u
                                updated_translations[name].proposals.splice(idx, 1)
                                save updated_translations
                              "Ok"



      DIV
        style: 
          position: 'fixed'
          bottom: 0
          left: 0
          width: WINDOW_WIDTH()
          zIndex: 999
          backgroundColor: 'rgba(220,220,220,.8)'
          textAlign: 'center'
          padding: '8px'

        BUTTON 
          className: 'primary_button'
          style: 
            backgroundColor: focus_color()
            marginTop: 0
            fontSize: 22
          onClick: => promote_temporary_translations(lang, @props.key)
          
          "Save Changes"


get_temporary_translations = (lang, key) ->
  key ||= '/translations'
  translations = fetch "#{key}/#{lang}"
  _.defaults fetch("local#{translations.key}"), JSON.parse(JSON.stringify(translations))


editable_translation = (id, updated_translations, style) -> 
  current_user = fetch '/current_user'
  val = null 
  if updated_translations[id]?.txt 
    val = updated_translations[id].txt
  else if updated_translations[id]?.proposals
    for proposal in updated_translations[id].proposals
      if proposal.u == current_user.user 
        val = proposal.txt 

  AutoGrowTextArea
    defaultValue: val
    style: _.defaults (style or {}),
      verticalAlign: 'top'
      fontSize: 'inherit'
      width: '100%'
    onChange: (e) -> 
      trans = e.target.value
      updated_translations[id] ||= {}

      if current_user.is_super_admin
        updated_translations[id].txt = trans 
        updated_translations[id].u = current_user.user 
      else 
        updated_translations[id].proposals ||= []
        found = false 
        for proposal in updated_translations[id].proposals
          if proposal.u == current_user.user 
            proposal.txt = trans 
            found = true 
            break 
        if !found 
          updated_translations[id].proposals.unshift {txt: trans, u: current_user.user}


      save updated_translations



promote_temporary_translations = (lang, key) ->
  key ||= '/translations'
  translations = fetch "#{key}/#{lang}"
  updated_translations = fetch "local#{translations.key}"
  Object.assign translations, updated_translations
  translations.key = "#{key}/#{lang}"
  save translations



window.TranslationsDash = TranslationsDash




##### 
# Dict will hold all the different translations for each language, 
#  i.e. dict.en, dict.spa, dict.ptbr, etc
# Each language's dict will have entries for every possible label that the 
# system needs to have a translation for. The entry can be a simple string, 
# or a function that will be passed arguments from t(). 

dict = {}


#########
# General
dict.en = 
  or: 'or'
  and: 'and'

  done: 'Done'
  cancel: 'cancel'
  edit: 'edit'
  share: 'share'
  delete: 'delete'
  close: 'close'
  update: 'Update'
  publish: 'Publish'
  closed: 'closed'
  add_new: 'add new'

dict.cs = 
  or: 'nebo'
  and: 'a'

  done: 'Hotovo'
  cancel: 'Smazat'
  edit: 'Upravit'
  share: 'Sdílet'
  delete: 'Smazat'
  close: 'Zavřít'
  update: 'Doplnit'
  publish: 'Uveřejnit'
  closed: 'Uzavřeno'
  add_new: 'Přidat nový'

dict.es = 
  or: 'ó'
  and: 'y'
  done: 'Hecho'
  cancel: 'cancelar'
  edit: 'editar'
  share: 'compartir'
  delete: 'eliminar'
  close: 'cerrar'
  update: 'Actualizar'
  publish: 'Publicar'
  closed: 'cerrado'
  add_new: 'crear nueva'


dict.pt = 
  or: 'ou'
  and: 'e'

  done: 'Pronto'
  cancel: 'cancelar'
  edit: 'editar'
  share: 'compartilhar'
  delete: 'apagar'
  close: 'fechar'
  update: 'Atualizar'
  publish: 'Publicar'
  closed: 'fechado'
  add_new: 'criar novo'

dict.aeb = 
  or: 'أو'
  and: 'و'

  done: 'منجز'
  cancel: 'إلغاء'
  edit: 'تعديل'
  share: 'أنقل'
  delete: 'إحذف'
  close: 'أغلق'
  update: 'حدّث'
  publish: 'أنشر'
  closed: 'مغلق'
  add_new: 'إضافة جديدة'

dict.fr = 
  or: 'ou'
  and: 'et'

  done: 'terminé' 
  cancel: 'annuler' 
  edit: 'modifier' 
  share: 'partager' 
  delete: 'effacer' 
  close: 'fermer' 
  update: 'mettre a jour' 
  publish: 'publier' 
  closed: 'fermé' 
  add_new: 'ajouter' 


#########
# Considerit opining

_.extend dict.en, 
  give_your_opinion: 'Give your Opinion'
  update_your_opinion: 'Update your Opinion'
  comment: 'comment'
  comments: 'comments'
  read_more: 'read more'
  select_these_opinions: 'Select these opinions'
  prev: 'prev'
  next: 'next'
  drag_from_left: (args) ->
    "Drag a #{args.noun} from the left"
  drag_from_right: (args) -> 
    "Drag a #{args.noun} from the right"
  write_a_new_point: (args) -> 
    "Write a new #{args.noun}"    

  slide_your_overall_opinion: 'Slide Your Overall Opinion'
  your_opinion: "Your opinion"
  save_your_opinion: 'Save your opinion'
  return_to_results: 'Return to results'
  skip_to_results: 'or just skip to the results'
  login_to_comment: 'Log in to write a comment'
  login_to_add_new: 'Log in to share an idea'
  login_to_save_opinion: 'Log in to save your opinion'
  discuss_this_point: 'Discuss this Point'
  save_comment: 'Save comment'
  write_a_comment: 'Write a comment'
  write_a_point: 'Write a point'
  summary_placeholder: 'A succinct summary of your point.'
  description_placeholder: 'Add background or evidence.'
  sign_name: 'Sign your name'

  tip_single: (args) -> 
    "Make one single point. Add multiple #{args.noun} if you have more."
  tip_direct: "Be direct. The summary is your main point."
  tip_review: "Review your language. Don’t be careless."
  tip_attacks: "No personal attacks."

  filter_to_watched: "Filter proposals to those you're watching"

_.extend dict.cs, 
  give_your_opinion: 'Přidat názor'
  update_your_opinion: 'Doplnit názor'
  comment: 'Komentář'
  comments: 'Komentáře'
  read_more: 'Číst více'
  select_these_opinions: 'Vybrat tyto možnosti'
  prev: 'předchozí'
  next: 'další'
  drag_from_left: (args) ->
    "Posunout zleva"
  drag_from_right: (args) -> 
    "Posunout zprava"
  write_a_new_point: (args) -> 
    "Napsat nový"    

  slide_your_overall_opinion: 'Posunout celkový názor'
  your_opinion: "Váš názor"
  save_your_opinion: 'Uložit názor'
  return_to_results: 'Vrátit se na výsledky'
  skip_to_results: 'přeskočit na výsledky'
  login_to_comment: 'Přihlásit se a napsat komentář'
  login_to_add_new: 'Přihlásit se a přidat nový'
  login_to_save_opinion: 'Přihlásit se a uložit názor'
  discuss_this_point: 'Diskutovat o názoru'
  save_comment: 'Uložit komentář'
  write_a_comment: 'Napsat komentář'
  write_a_point: 'Napsat názor'
  summary_placeholder: 'Stručné shrnutí názoru'
  description_placeholder: 'Přidat detaily nebo důkazy'
  sign_name: 'Napsat jméno'

  tip_single: (args) -> 
    "Vložte jeden komentář. Přidejte i více komentářů, pokud máte. "
  tip_direct: "Buďte struční. Shrnutí je váš hlavní cíl."
  tip_review: "Raději znovu zkontrolujte, co jste napsali."
  tip_attacks: "Žádné osobní útoky."

  filter_to_watched: "Filtrovat návrhy jen na ty, které sledujete"


_.extend dict.es, 
  give_your_opinion: 'Deja tu Opinion'
  update_your_opinion: 'Actualizar tu Opinion'
  comment: 'comentario'
  comments: 'comentarios'
  read_more: 'ver más'
  select_these_opinions: 'Selecciona estas opiniones'
  prev: 'anterior'
  next: 'siguiente'
  drag_from_left: (args) ->
    return "Arrastra un #{args.noun} de la izquierda"

  drag_from_right: (args) ->
    return "Arrastra un #{args.noun} de la derecha"

  write_a_new_point: (args) ->
    return "Escribe un nuevo #{args.noun}"

  # Alejandro, please translate:
  slide_your_overall_opinion: 'Desliza Tu Opinión General'
  your_opinion: "Tu opinión"
  save_your_opinion: 'Guarda tu opinión'
  return_to_results: 'Volver a los resultados'
  skip_to_results: 'o ir directamente a los resultados'
  login_to_comment: 'Inicia sesión para comentar'
  login_to_add_new: 'Inicia sesión para crear nueva'
  login_to_save_opinion: 'Inicia sesión para guarda tu opinión'
  discuss_this_point: 'Debatir este Punto'
  save_comment: 'Guardar comentario'
  write_a_comment: 'Escribir comentario'
  write_a_point: 'Escribir un punto de vista'
  summary_placeholder: 'Un breve resumen de tu punto de vista.'
  description_placeholder: 'Añadir antecedentes o pruebas'
  sign_name: 'Firmar con tu nombre'
  tip_single: (args) -> 
    "Escribe una única opinión. Añade multiples #{args.noun} si tienes más."
  tip_direct: "Se directo. El resumen será tu punto de vista principal."
  tip_review: "Revisa tu lenguaje. No seas descuidado."
  tip_attacks: "No ataques personales."
  filter_to_watched: "Filtrar propuestas por las que estás observando"

_.extend dict.pt, 
  give_your_opinion: 'Dê sua opinião'
  update_your_opinion: 'Atualizar sua opinião'
  comment: 'comentar'
  comments: 'comentários'
  read_more: 'leia mais'
  select_these_opinions: 'Selecione estas opiniões'
  prev: 'ant'
  next: 'prox'
  drag_from_left: (args) ->
    "Arrastar uma #{args.noun} da esquerda"
  drag_from_right: (args) -> 
    "Arrastar uma #{args.noun} da direita"
  write_a_new_point: (args) -> 
    "Escrever uma nova #{args.noun}"    

  slide_your_overall_opinion: 'Deslize e defina sua Opinião Geral'
  your_opinion: "Sua opinião"
  save_your_opinion: 'Salvar sua opinião'
  return_to_results: 'Voltar para os resultados'
  skip_to_results: 'ou vá direto para os resultados'
  login_to_comment: 'Conecte-se para comentar'
  login_to_add_new: 'Conecte-se para adicionar um novo'
  login_to_save_opinion: 'Conecte-se para salvar sua opinião'
  discuss_this_point: 'Discutir este Ponto'
  save_comment: 'Salvar comentário'
  write_a_comment: 'Escrever um comentário'
  write_a_point: 'Escrever um ponto de vista'
  summary_placeholder: 'Um breve resumo do seu Ponto de Vista.'
  description_placeholder: 'Inclua seus argumentos e evidências.'
  sign_name: 'Assinar'

  tip_single: (args) -> 
    "Escreve seu ponto de vista. Inclua multiplos #{args.noun} se tiver mais."
  tip_direct: "Seja direto. O resumo é seu ponto de vista principal."
  tip_review: "Reveja sua linguagem. Não seja desleixado(a)."
  tip_attacks: "Não faça ataques pessoais."

  filter_to_watched: "Filtrar propostas daqueles que está observando"


_.extend dict.aeb, 
  give_your_opinion: 'أبد رأيك'
  update_your_opinion: 'بد رأيك من جديد'
  comment: 'علّق'
  comments: 'تعليقات'
  read_more: 'اقرأ المزيد'
  select_these_opinions: 'اختر هذه الآراء'
  prev: 'السابق'
  next: 'اللاحق'
  drag_from_left: (args) ->   
    "من اليسار #{args.noun} اسحب"
  drag_from_right: (args) -> 
    "من اليمين #{args.noun}اسحب"
  write_a_new_point: (args) ->     
    "(ة) جديد #{args.noun}اكتب"

  slide_your_overall_opinion: 'حدّد رأيك العامّ'
  your_opinion: "رأيك"
  save_your_opinion: 'احفظ رأيك'
  return_to_results: 'العودة إلى النتائج'
  skip_to_results: 'أو مر مباشرة إلى النتائج'
  login_to_comment: 'سجّل لكتابة تعليق'
  login_to_add_new: 'سجّل لإضافة الجديد'
  login_to_save_opinion: 'سجل لحفظ رأيك'
  discuss_this_point: 'ناقش هذه النقطة'
  save_comment: 'احفظ التعليق'
  write_a_comment: 'اكتب تعليق'
  write_a_point: 'اكتب وجهة نظر'
  summary_placeholder: 'تلخيص موجز لوجهة نظرك'
  description_placeholder: '.أضف خلفيّات أو دلائل/ اثباتات'
  sign_name: 'أدخل اسمك'

  tip_single: (args) -> 
    "أبد وجهة نظر واحدة. أضف إن كان لديك المزيد."
  tip_direct: "كن موجزا. الملخص هو وجهة نظرك الرئيسية"
  tip_review: "راجع لغتك. لا تكن مهملا."
  tip_attacks: "الهجوم الشخصي ممنوع"

  filter_to_watched: "إفرز مقترحات من تتابعهم."


_.extend dict.fr,
  give_your_opinion: 'Donnez votre opinion' 
  update_your_opinion: 'modifiez votre opinion' 
  comment: 'commentez'
  comments: 'commentaires' 
  read_more: 'Voir plus' 
  select_these_opinions: 'choisissez ces opinions' 
  prev: 'précédent' 
  next: 'suivant' 
  drag_from_left: (args) -> 
    "glissez un #{args.noun} de la gauche"
  drag_from_right: (args) -> 
    "glissez un #{args.noun} de la droite"
  write_a_new_point: (args) -> 
    "ecrivez un nouvel argument #{args.noun}"

  slide_your_overall_opinion: 'ajustez votre sentiment général' 
  your_opinion: "votre opinion" 
  save_your_opinion: 'enregistrez votre opinion' 
  return_to_results: 'retour aux résultats' 
  skip_to_results: 'aller directement aux résultats' 
  login_to_comment: 'connectez-vous pour écrire un commentaire' 
  login_to_add_new: 'connectez-vous pour ajouter' 
  login_to_save_opinion: 'connectez-vous pour enregistrer votre opinion' 
  discuss_this_point: 'discutez ce point' 
  save_comment: 'enregistrer le commentaire' 
  write_a_comment: 'Ecrire un commentaire' 
  write_a_point: 'Ecrire un argument' 
  summary_placeholder: 'Un résumé bref de votre argument.'
  description_placeholder: 'Ajouter du contexte ou des temoignages.' 
  sign_name: 'Signature' 

  tip_single: (args) -> 
    "Un argument a la fois. Ajoutez plusieurs #{args.noun} si vous en avez plus." 
  tip_direct: "Soyez direct. le résumé est votre argument principal" 
  tip_review: "Soignez votre vocabulaire. Relisez vous." 
  tip_attacks: "Evitez les attaques personnelles." 

  filter_to_watched: "Visualiser uniquement les propositions que vous suivez" 



#########
# Creating proposal


_.extend dict.en, 
  create_new_proposal: 'Create new proposal'
  error_free: "free of language errors"
  unambiguous: 'unambiguous'
  make_it: 'Make it'
  url_instr: "Just letters, numbers, underscores, dashes."
  summary: 'Summary'
  proposal_summary_instr: 'Clear and concise summary'
  details: 'Details'
  label: 'Label'
  expandable_body_instr: 'Text that is shown when expanded'
  add_expandable: "Add expandable description section"
  category: 'Category'
  optional: 'optional'
  show_on_homepage: 'List on homepage?'
  open_for_discussion: 'Open for discussion?'
  permissions_and_invites: 'Permissions'

_.extend dict.cs, 
  create_new_proposal: 'Vytvořit nový návrh'
  error_free: "bez gramatických chyb"
  unambiguous: 'jednoznačný'
  make_it: 'Provést'
  url_instr: "Jen písmena, číslice, podtržítka, pomlčky."
  summary: 'Shrnutí'
  proposal_summary_instr: 'Cílit na 3-8 slov, podstatných jmen a sloves.'
  details: 'Detaily'
  label: 'Štítek'
  expandable_body_instr: 'Text, který se zobrazí po rozšíření'
  add_expandable: "Přidat rozšířený popis"
  category: 'Kategorie'
  optional: 'Volitelné'
  show_on_homepage: 'Seznam na homepage?'
  open_for_discussion: 'Otevřeno pro diskusi?'
  permissions_and_invites: 'Povolení'


_.extend dict.es, 
  create_new_proposal: 'Crear nueva propuesta'
  error_free: "libre de errores ortográficos"
  unambiguous: 'sin ambiguedades'
  make_it: 'Hazlo'
  url_instr: "Solo letras, numeros, subrayados, guiones."
  summary: 'Resumen'
  proposal_summary_instr: 'Que sean 3-8 palabras con un verbo y un sustantivo.'
  details: 'Detalles'
  label: 'Etiqueta'
  expandable_body_instr: 'Texto mostrado al expandir'
  add_expandable: "Añadir una sección de descripción expandible"
  category: 'Categoría'
  optional: 'opcional'
  show_on_homepage: '¿Mostrar en portada?'
  open_for_discussion: '¿Abierta a debate?'
  permissions_and_invites: 'Permisos'

_.extend dict.pt, 
  create_new_proposal: 'Criar nova proposta'
  error_free: "livre de erros ortográficos"
  unambiguous: 'sem ambiguidades'
  make_it: 'Faça'
  url_instr: "Apenas letras, números, underscores e traços."
  summary: 'Sumário'
  proposal_summary_instr: 'Entre 3-8 palavras com um verbo e um substantivo.'
  details: 'Detalhes'
  label: 'Rótulo'
  expandable_body_instr: 'Texto exibido quando expandido'
  add_expandable: "Adicionar uma seção de descrição expandida"
  category: 'Categoria'
  optional: 'opcional'
  show_on_homepage: 'Exibir na página inicial?'
  open_for_discussion: 'Abrir para discussão?'
  permissions_and_invites: 'Permissões'

_.extend dict.aeb,
  create_new_proposal: 'إحدث مقترح جديد'
  error_free: "خال من الأخطاء اللغويّة"
  unambiguous: 'خال من الغموض'
  make_it: 'أنجز'
  url_instr: "مجرّد حروف وأرقام وأشرطة سفلية ومطّات"
  summary: 'ملخص'
  proposal_summary_instr: 'اهدف إلي 3-8 كلمات من بينها فعل واسم'
  details: 'تفاصيل'
  label: ' مسمّى'
  expandable_body_instr: 'النص الذي يظهر عند التوسيع'
  add_expandable: "أضف قسم مخصّص للوصف القابل للتوسيع"
  category: 'فئة'
  optional: 'اختياري'
  show_on_homepage: 'أدرج على الصفحة الرئيسية؟'
  open_for_discussion: 'إفتح للمناقشة؟'
  permissions_and_invites: 'رخص ودعوات'


_.extend dict.fr, 
  create_new_proposal: 'Créer une nouvelle proposition' 
  error_free: "sans fautes de frappe" 
  unambiguous: 'sans ambiguité' 
  make_it: 'Allez y'
  url_instr: "Lettres, chiffres, tirets uniquement." 
  summary: 'Résumé' 
  proposal_summary_instr: 'Visez 3-8 mots avec un verbe et un complement.'
  details: 'Détails' 
  label: 'Sous-titre' 
  expandable_body_instr: 'Le texte qui s’affiche dans la sous section'
  add_expandable: "Ajouter une sous section a la description" 
  category: 'Catégorie' 
  optional: 'Optionnel' 
  show_on_homepage: 'Afficher en page principale?' 
  open_for_discussion: 'Ouvert a a discussion?'
  permissions_and_invites: 'Permissions' 


########
# authentication / user account related translations

_.extend dict.en, 
  log_in: 'Log in'
  create_an_account: 'Create an account'  
  create_new_account: 'Create account'
  log_out: 'Log out'
  edit_profile: 'Edit Profile'
  email_settings: 'Email Settings'
  introduce_yourself: 'Please introduce yourself'

  complete_registration: 'Complete registration'
  login_as: 'Your email'
  password: 'Password'
  name_prompt: 'Your name'
  full_name: (args) -> 
    subdomain = fetch '/subdomain'
    if subdomain.name in ['bitcoin', 'bitcoinclassic']
      'user name or company name'
    else
      'first and last name or pseudonym'
  pic_prompt: 'Your picture'
  your_profile: 'Update Your Profile'
  updated_successfully: "Updated successfully"
  reset_your_password: "Reset Your Password"
  code: 'Code'
  new_password: 'New password'
  verification_sent: 'We just emailed you a verification code. Copy / paste it below.'
  verify: 'Verify'
  choose_password: "choose a new password"
  code_from_email: 'verification code from email'
  verify_your_email: 'Verify Your Email'
  more_info: 'Please give some info'
  forgot_password: 'Help! I forgot my password'

_.extend dict.cs, 
  log_in: 'Přihlásit se'
  create_new_account: 'Vytvořit nový účet'
  log_out: 'Odhlásit se'
  edit_profile: 'Upravit profil'
  email_settings: 'Nastavení e-mailu'
  introduce_yourself: 'Představte se'

  complete_registration: 'Dokončit registraci'
  login_as: 'Ahoj, přihlašuji se jako'
  password: 'Moje heslo'
  name_prompt: 'Jmenuji se'
  full_name: 'Moje jméno'
  pic_prompt: 'Moje fotka'
  your_profile: 'Váš profil'
  updated_successfully: "úspěšně upraven"
  reset_your_password: "Obnovit heslo"
  code: 'Kód'
  new_password: 'Nové heslo'
  verification_sent: 'Poslali jsme vám ověřovací kód na e-mail. Zkopírujte jej níže.'
  verify: 'Ověřit'
  choose_password: "Zvolit nové heslo"
  code_from_email: 'ověřovací kód z e-mailu'
  verify_your_email: 'Ověřit e-mail'
  more_info: 'Prosím doplňte více informací'
  forgot_password: 'Zapomněl jsem heslo!'


_.extend dict.es, 
  log_in: 'Entrar'
  create_new_account: 'Registrarse'
  log_out: 'Salir'
  edit_profile: 'Editar Perfil'
  email_settings: 'Configuración de Email'
  introduce_yourself: 'Descríbete'

  # Alejandro, please translate:
  complete_registration: 'Completar registro'
  login_as: 'Hola, inicio sesión como'
  password: 'contraseña'
  name_prompt: 'Mi nombre es'
  full_name: 'nombre completo'
  pic_prompt: 'mi foto'
  your_profile: 'Tu Perfil'
  updated_successfully: "Actualizado correctamente"
  reset_your_password: "Reestablecer Contraseña"
  code: 'Codigo'
  new_password: 'Nueva contraseña'
  verification_sent: 'Te hemos enviado un código de verificación via email.'
  verify: 'Verificar'
  choose_password: "elige una nueva contraseña"
  code_from_email: 'código de verificación recibido'
  verify_your_email: 'Verifica Tu Email'
  more_info: 'Por favor, proporciona alguna información'
  forgot_password: '¡He olvidado mi contraseña!'


_.extend dict.pt, 
  log_in: 'Entrar'
  create_new_account: 'Criar nova conta'
  log_out: 'Sair'
  edit_profile: 'Editar Perfil'
  email_settings: 'Configurações de Email'
  introduce_yourself: 'Identifique-se'

  complete_registration: 'Completar registro'
  login_as: 'Logar como'
  password: 'senha'
  name_prompt: 'Meu nome é'
  full_name: (args) -> 
    subdomain = fetch '/subdomain'
    if subdomain.name in ['bitcoin', 'bitcoinclassic']
      'nome de usuário ou nome da empresa'
    else
      'nome e sobrenome'
  pic_prompt: 'Minha foto'
  your_profile: 'Seu Perfil'
  updated_successfully: "Atualizado com sucesso"
  reset_your_password: "Criar nova senha"
  code: 'Código'
  new_password: 'Nova senha'
  verification_sent: 'Enviamos um código de verificação para o seu email.'
  verify: 'Verificar'
  choose_password: "escolher uma nova senha"
  code_from_email: 'código de verificação do email'
  verify_your_email: 'Verifique seu Email'
  more_info: 'Por favor, forneça algumas informações'
  forgot_password: 'Esqueci minha senha!'

_.extend dict.aeb, 
  log_in: 'سجّل للخول'
  create_new_account: 'إنشاء حساب جديد'
  log_out: 'خروج'
  edit_profile: 'تعديل البيانات الشخصية'
  email_settings: 'إعدادات البريد الإلكتروني'
  introduce_yourself: 'عرف بنفسك'

  complete_registration: 'اكمل التسجيل'
  login_as: 'مرحبا،أسجّل الدخول باسم'
  password: 'كلمه السر'
  name_prompt: 'اسمي'
  full_name: 'إسم المستخدم'
  pic_prompt: 'أنا أشبه'
  your_profile: 'بياناتك الشخصية'
  updated_successfully: "تم التحديث بنجاح"
  reset_your_password: "إعادة تعيين كلمة السر"
  code: '  رمز'
  new_password: ' كلمة السر الجديدة'
  verification_sent: 'لقد أرسلنا إليك رمز التحقق عبر البريد الإلكتروني. انسخ /ألصق أدناه.'
  verify: 'تحقّق'
  choose_password: "اختر كلمة سر جديدة"
  code_from_email: 'رمز التحقق من البريد الإلكتروني'
  verify_your_email: ' تحقق من البريد الإلكتروني الخاص بك'
  more_info: 'الرجاء إعطاء بعض المعلومات'
  forgot_password: 'لقد نسيت كلمة السر الخاصة بي'


_.extend dict.fr, 
  log_in: 'Connection' 
  create_new_account: 'Créez un nouveau compte' 
  log_out: 'Déconnection' 
  edit_profile: 'Editez votre profil' 
  email_settings: 'Réglages des courriels' 
  introduce_yourself: 'Présentez-vous' 

  complete_registration: 'Finalisez votre inscription' 
  login_as: 'Je me connecte avec' 
  password: 'Mon mot de passe est' 
  name_prompt: 'Je m’appelle' 
  full_name: 'Mon nom d’utilisateur est'  
  pic_prompt: 'Je ressemble à'   
  your_profile: 'Votre profil' 
  updated_successfully: "Mise a jour réussie" 
  reset_your_password: "Réinitalisez votre mot de passe"  
  code: 'Code'
  new_password: 'Nouveau mot de passe' 
  verification_sent: 'Copiez et collez ci-dessous le code de vérification envoyé par courriel.'

  verify: 'Verification' 
  choose_password: "Choisissez votre nouveau mot de passe" 
  code_from_email: 'code de vérification reçu par courriel'  
  verify_your_email: 'Verifiez votre e mail' 
  more_info: 'Veuillez fournir des informations' 
  forgot_password: 'mot de passe oublié' 


########
# email notification settings

_.extend dict.en, 

  send_email: 'Send me email summaries of activity'
  email_digest_purpose: (args) ->
    "The emails summarize relevant new activity for you regarding #{args.project}"
  digest_timing: "Send email summaries at most"
  daily: 'daily'
  hourly: 'hourly'
  weekly: 'weekly'
  monthly: 'monthly'
  notable_events: "Emails are only sent if a notable event occurred. Which events are notable to you?"
  watched_proposals: 'The proposals you are watching for new activity'
  unwatch: "Unwatch this proposal"
  hide_notifications: 'Hide notifications'
  show_notifications: 'Show notifications'
  commented_on: "commented on"
  your_point: 'your point'
  edited_proposal: 'edited this proposal'
  added_new_point: 'added a new point'
  added_opinion: 'added their opinion'

_.extend dict.cs, 
  send_email: 'Posílejte mě novinky na e-mail'
  email_digest_purpose: (args) ->
    "Novinky shrnují poslední aktivity"
  digest_timing: "Posílat shrnutí"
  daily: 'denně'
  hourly: 'každou hodinu'
  weekly: 'týdně'
  monthly: 'měsíčně'
  notable_events: "E-maily jsou rozesílány, pokud došlo k něčemu zajímavému. Co je pro vás zajímavé?"
  watched_proposals: 'Návrhy, které sledujete:'
  unwatch: "Přestat sledovat tento návrh"
  hide_notifications: 'Skrýt oznámení'
  show_notifications: 'Ukázat oznámení'
  commented_on: "Vložen komentář na"
  your_point: 'váš názor'
  edited_proposal: 'upravený návrh'
  added_new_point: 'přidán nový názor'
  added_opinion: 'přidán jejich názor'


_.extend dict.es, 
  send_email: 'Envíame resúmenes por correo electrónico'
  email_digest_purpose: (args) ->
    "Los resumenes proporcionan información de actividad sobre #{args.project}"
  digest_timing: "Envíame resúmenes como máximo"
  daily: 'diariamente'
  hourly: 'cada hora'
  weekly: 'semanalmente'
  monthly: 'mensualmente'
  notable_events: "Los Emails únicamente se envían si ocurre algo importante. ¿Qué eventos son importantes para tí?"
  watched_proposals: 'Las propuestas que estás observando:'
  unwatch: "Dejar de seguir esta propuesta"
  hide_notifications: 'Ocultar notificaciones'
  show_notifications: 'Mostrar notificaciones'
  commented_on: "comentado"
  your_point: 'tu punto de vista'
  edited_proposal: 'ha editado esta propuesta'
  added_new_point: 'ha añadido un nuevo punto de vista'
  added_opinion: 'ha añadido su opinión'

_.extend dict.pt, 

  send_email: 'Me envie notificações por email'
  email_digest_purpose: (args) ->
    "As notificações resumem novas atividades sobre #{args.project}"
  digest_timing: "Envie resumos"
  daily: 'diários'
  hourly: 'por hora'
  weekly: 'semanais'
  monthly: 'mensais'
  notable_events: "Emails só serão enviados para avisar eventos importantes. Quais eventos são importantes para você?"
  watched_proposals: 'As propostas que você está seguindo:'
  unwatch: "Deixar de seguir esta proposta"
  hide_notifications: 'Ocultar notificações'
  show_notifications: 'Mostrar notificações'
  commented_on: "comentado em"
  your_point: 'seu ponto de vista'
  edited_proposal: 'editou esta proposta'
  added_new_point: 'adicionou novo ponto de vista'
  added_opinion: 'adicionou sua opinião'

_.extend dict.aeb,
  send_email: 'أرسل لي ملخصات البريد الإلكتروني'
  email_digest_purpose: (args) ->
    "#{args.project} ترصد الملخّصات الأنشطة الجديدة ذات الجدوى بالنسبة لك نظرا ل"
  digest_timing: "أرسل الملخّص كل"
  daily: 'يوم'
  hourly: 'ساعة'
  weekly: 'أسبوع'
  monthly: 'شهر'
  notable_events: "يتم إرسال رسائل البريد الإلكتروني إلا إذا وقع حدث بارز.  أي حدث يتمّ اعتباره بارزا بالنسبة لك؟"
  watched_proposals: 'الاقتراحات التي تشاهدها لهذا النشاط الجديد'
  unwatch: "عدم مشاهدة هذا الاقتراح"
  hide_notifications: 'أخف التنبيهات'
  show_notifications: 'اكشف التنبيهات'
  commented_on: "علّق على"
  your_point: 'وجهة نظرك'
  edited_proposal: 'عدل هذا الاقتراح'
  added_new_point: 'أضف وجهة نظر أخرى'
  added_opinion: 'أضافوا أراءهم'

_.extend dict.fr, 
  send_email: 'Envoyez-moi des courriels récapitulaitfs' 
  email_digest_purpose: (args) ->
    "Les récapitulatifs résument l’activité nouvelle qui vous intéresse au sujet de #{args.project}"

  digest_timing: "Fréquence d’envoi maximale"

  daily: 'quotidienne' 
  hourly: 'toutes les heures' 
  weekly: 'hebdomadaire' 
  monthly: 'mensuelle' 
  notable_events: "Choisissez les évenements qui déclenchent l’envoi d’un courriel recapitulatif?" 
  watched_proposals: 'Les propositions dont vous suivez l’activité:' 
  unwatch: "Ne plus suivre cette proposition" 
  hide_notifications: 'Masquer les notifications' 
  show_notifications: 'Montrer les notifications' 
  commented_on: "Commenté le" 
  your_point: 'votre argument' 
  edited_proposal: 'a edité cette proposition' 
  added_new_point: 'a ajouté un argument' 
  added_opinion: 'ont ajouté leur opinion' 

# fill in missing spanish translations with english equivalents
_.defaults dict.es, dict.en

# fill in missing brazilian portuguese translations with english equivalents
_.defaults dict.pt, dict.en
