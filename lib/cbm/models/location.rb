module CBM
  class Location < Neography::Node

    def self.cities(name="*")
      cypher = "START me = node:city_index('name:*#{name}*')
                WHERE me.country_id = 213
                RETURN ID(me), me.name
                LIMIT 5"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end
    end

    def self.regions(name="*")
      cypher = "START me = node:region_index('name:*#{name}*')
                RETURN ID(me), me.name
                LIMIT 5"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end
    end

    def self.countries(name="*")
      cypher = "START me = node:country_index('name:*#{name}*')
                RETURN ID(me), me.name
                LIMIT 5"
      results = $neo_server.execute_query(cypher)

      if results
        results["data"]
      else
        []
      end
    end

    def users
      cypher = "START me = node(#{self.neo_id})
                MATCH me <-[:has_location]- users
                RETURN users.uid, users.name, users.image_url"
      results = $neo_server.execute_query(cypher)
      results["data"]

    end


  end
end