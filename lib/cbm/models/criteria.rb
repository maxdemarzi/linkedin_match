module CBM
  class Criteria < Neography::Node

    def self.all
      cypher = "START me = node:criteria_index('uid:*')
                RETURN me.uid, me.name, me.formula"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end
    end

    def self.get_by_id(ids)
      cypher = "START me = node({ids})
                RETURN me.uid, me.name, me.formula"
      results = $neo_server.execute_query(cypher, :ids =>ids)

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
    #   - name
    #   - formula (using node_ids)
    #
    def self.create(name, formula)
      uid = UUIDTools::UUID.random_create.to_s
      node = $neo_server.create_unique_node("criteria_index", "uid", uid,
                                            {:uid      => uid,
                                             :name     => name,
                                             :formula  => formula,
                                             :type     => "criteria"})
      criteria_node = Criteria.load(node)
      Path.create_from_criteria(criteria_node)
      criteria_node
    end

  end
end