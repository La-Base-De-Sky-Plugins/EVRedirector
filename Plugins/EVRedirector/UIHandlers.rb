#===============================================================================
# UI module
#===============================================================================
module UIHandlers

  @@options_labels = {}
  class << self
    alias_method :mui_add, :add
    alias_method :mui_remove, :remove
    alias_method :mui_clear, :clear
    alias_method :mui_edit_hash, :edit_hash
    
    def add(ui, option, hash)
      mui_add(ui, option, hash)
      if hash["options"] && hash["options_labels"]
        @@options_labels[ui] ||= {}
        @@options_labels[ui][option] ||= {}
        @@options_labels[ui][option] = hash["options_labels"]
        if hash["options_labels"].keys != hash["options"]
          remaining_options = hash["options_labels"].keys - hash["options"]
          all_options = hash["options"] + remaining_options
          edit_hash(ui, option, "options", all_options)
        end
      elsif hash["options_labels"]
        edit_hash(ui, option, "options", hash["options_labels"].keys)
        @@options_labels[ui] ||= {}
        @@options_labels[ui][option] ||= {}
        @@options_labels[ui][option] = hash["options_labels"]
      end
    end
    
    def remove(ui, option)
      mui_remove(ui, option)
      @@options_labels[ui]&.delete(option)
    end
    
    def clear(ui)
      mui_clear(ui)
      @@options_labels[ui]&.clear
    end
    
    def edit_hash(menu, page, field, new_data)
      mui_edit_hash(menu, page, field, new_data) if field != "options_labels"
      if field == "options_labels"
        if new_data.is_a?(Hash)
          @@options_labels[menu] ||= {}
          @@options_labels[menu][page] ||= {}
          @@options_labels[menu][page] = new_data
        end
      end
    end
  end

  module_function
  def exists?(menu, page)
    return true if @@handlers && @@handlers[menu] && @@handlers[menu][page]
    false
  end

  def define_option_label(menu, page, option, label)
    return unless exists?(menu, page)
    options = get_info(menu, page, :options)
    unless options.include?(option)
      options << option
    end
    @@options_labels[menu] ||= {}
    @@options_labels[menu][page] ||= {}
    @@options_labels[menu][page][option] = label
    edit_hash(menu, page, "options", options)
  end

  # Recibe el menu, la pagina, y luego un hash cuya clave es la clave de la opcion y el valor un string.
  def define_options_labels(menu, page, options_with_labels)
    return unless exists?(menu, page)
    options_with_labels.each_pair do |key, value|
      define_option_label(menu, page, key, value)
    end
  end
end