module CBM
  class Path < Neography::Node

    def self.find_by_description(description)
      path = $neo_server.get_node_index("path_index", "description", description)

      if path && path.first["data"]["description"]
        self.new(path.first)
      else
        nil
      end
    end

    def self.create(description)
      node = $neo_server.create_unique_node("path_index", "description", description, {:description => description, :type => "path"})

      node_id = node["self"].split('/').last.to_i
      commands = get_rels(description, node_id)
      batch_results = $neo_server.batch *commands

      set_path(batch_results, node_id)

      Path.load(node)
    end

    def self.set_path(batch_results, node_id)
      commands = []
      batch_results.each do |b|
        commands << [:set_relationship_property, b["body"]["self"].split("/").last, {:path => node_id}]
      end
      $neo_server.batch *commands
    end

    # Take description and create the actual paths (relationships between nodes)
    #
    def self.get_rels(description,node_id)
      from = nil
      rel = nil
      to = nil
      in_path = nil
      commands = []

      description.split(/(\d+)/).each do |c|
        next if c == ""

        case
          when from.nil?
            from = c.to_i
          when ["&!","&"].include?(c)
            rel = c
            in_path = (c == "&") ? "in_path" : "in_path_excluded"
          when to.nil?
            to = c.to_i
            commands << [:create_unique_relationship, "in_path_index", "from_c_to_path_id",
                         "#{from}_#{rel}_#{to}_#{node_id}", in_path, from, to]
            from = to
            to = nil
        end
      end
      commands << [:create_unique_relationship, "in_path_index", "from_c_to",
                   "#{from}_&_#{node_id}", "in_path", from, node_id]

      commands
    end

    # criteria.formula should equal something like "(17 and 87) or (17 and 35)"
    def self.create_from_criteria(criteria)

      paths = Path.get_paths(criteria)
      path_nodes = []

      paths.each do |path|
        path_nodes << Path.create(path)
      end

      # Connect the criteria to these paths
      commands = []
      path_nodes.each do |p|
        commands << [:create_unique_relationship, "in_criteria_index", "path_criteria",
                     "#{p.description}-#{criteria.uid}",
                     "in_criteria", p.neo_id, criteria]
      end
      batch_results = $neo_server.batch *commands

      commands = []
      batch_results.each_with_index do |b, index|
        path_id = path_nodes[index].neo_id.to_i
        commands << [:set_relationship_property, b["body"]["self"].split("/").last, {:path => path_id}]
      end
      $neo_server.batch *commands

    end

    def self.get_paths(criteria)
      expression = criteria.formula.dup

      variables = ['(', ')', 'and', 'or', '&&' , '||', '!', 'not'].inject(criteria.formula) do |exp, op|
        exp.gsub(op, ' ')
      end.gsub(/\s+/, ' ').split(' ').uniq.reject { |v| ["true", "false"].include?(v) }

      # Express in terms of v[0], v[1], etc
      variables.each_with_index do |var, index|
        expression.gsub!(var, "v[#{index}]")
      end

      # Generate optimal formula
      tt = TruthTable.new {|v| eval(expression) }
      formula = tt.formula

      # Replace v[0], v[1] with the ids
      variables.each_with_index do |var, index|
        formula.gsub!("v[#{index}]", var)
      end

      # 2&3 = in_path
      # 3&!4 = in_path and excluded

      formula.split('|').collect{ |path|
        order_path(path)
      }
    end

    def self.order_path(path)
      path.strip!
      elements = Hash.new
      ordered_path = ""
      path.split(/(\d+)/).each_slice(2) do |slice|
        slice[0] = "&" if slice[0].empty?
        elements[slice[1]] = slice[0]
      end
      elements.sort{|a, b| a[0] <=> b[0]}.each do |e|
        ordered_path << e[1] + e[0]
      end
      raise(ArgumentError, "first relationship cannot be a not!") if ordered_path[0..1] == "&!"
      ordered_path[1..-1]
    end

  end
end