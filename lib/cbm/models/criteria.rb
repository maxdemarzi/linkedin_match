module CBM
  class Criteria < Neography::Node

    def self.all
      cypher = "START me = node:criteria_index('name:*')
                RETURN me.uid, me.name, me.formula"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end

    end

    def self.find_by_uid(uid)
      criteria = $neo_server.get_node_index("criteria_index", "uid", uid)

      if criteria && criteria.first["data"]["uid"]
        self.new(criteria.first)
      else
        nil
      end
    end

    # Create the Criteria
    # Expects:
    #   - uid
    #   - name
    #   - formula (using node_ids)
    #
    def self.create(criteria)
      node = $neo_server.create_unique_node("criteria_index", "uid", criteria["uid"],
                                            {:uid      => criteria["uid"],
                                             :name     => criteria["name"],
                                             :formula  => criteria["formula"]})
      criteria_node = Criteria.load(node)
      Path.create_from_criteria(criteria_node)
      criteria_node
    end

  end
end