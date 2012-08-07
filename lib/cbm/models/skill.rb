module CBM
  class Skill < Neography::Node

    def self.find_by_name(name)
      skill = $neo_server.get_node_index("skill_index", "uid", name)

      if skill
        self.new(skill.first)
      else
        nil
      end
    end

    def users
      cypher = "START me = node(#{self.neo_id})
                MATCH me <-[:has]- users
                RETURN users.uid, users.name, users.image_url"
      results = $neo_server.execute_query(cypher)
      results["data"]
    end

    def users_count
      cypher = "START me = node(#{self.neo_id})
                MATCH me <-[:has]-> users
                RETURN COUNT(users)"
      results = $neo_server.execute_query(cypher)
      results["data"][0][0]
    end

  end
end
