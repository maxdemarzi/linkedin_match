module CBM
  class Path < Neography::Node
    @neo_server = Neography::Rest.new

    def self.find_by_description(description)
      path = @neo_server.get_node_index("path_index", "description", description)

      if path && path.first["data"]["description"]
        self.new(path.first)
      else
        nil
      end
    end

    def self.create(description)
      node = @neo_server.create_unique_node("path_index", "description", description, {:description => description})
      #TODO: Take description and create the actual paths (relationships between nodes)
      Path.load(node)
    end

    # criteria.formula should equal something like "(17 and 87) or (17 and 35)"
    def self.create_from_criteria(criteria)
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

      # & = in_path
      # &! = in_path and excluded

      paths = formula.split('|').each{|t| t.strip!}

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
      @neo_server.batch *commands

    end

  end
end