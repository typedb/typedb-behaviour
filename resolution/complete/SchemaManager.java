package grakn.verification.resolution.complete;

import grakn.client.GraknClient;
import grakn.client.concept.AttributeType;
import grakn.client.concept.RelationType;
import grakn.client.concept.Role;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;

import static grakn.verification.resolution.common.Utils.loadGqlFile;

public class SchemaManager {
    private static final Path SCHEMA_PATH = Paths.get("resolution", "complete", "completion_schema.gql").toAbsolutePath();
    ;

    private static HashSet<String> EXCLUDED_ENTITY_TYPES = new HashSet<String>() {
        {
            add("entity");
        }
    };

    private static HashSet<String> EXCLUDED_RELATION_TYPES = new HashSet<String>() {
        {
            add("relation");
            add("var-property");
            add("isa-property");
            add("has-attribute-property");
            add("relation-property");
            add("resolution");
        }
    };

    private static HashSet<String> EXCLUDED_ATTRIBUTE_TYPES = new HashSet<String>() {
        {
            add("attribute");
            add("label");
            add("rule-label");
            add("type-label");
            add("role-label");
        }
    };

//  TODO manage rules - reading and deleting before forward-chaining

    public static void addResolutionSchema(GraknClient.Session session) {
        try {
            loadGqlFile(session, SCHEMA_PATH);
        } catch (IOException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static Role getRole(GraknClient.Transaction tx, String roleLabel) {
        GraqlGet roleQuery = Graql.match(Graql.var("x").sub(roleLabel)).get();
        return tx.execute(roleQuery).get(0).get("x").asRole();
    }

    public static void connectResolutionSchema(GraknClient.Session session) {
        try (GraknClient.Transaction tx = session.transaction().write()) {
            Role instanceRole = getRole(tx, "instance");
            Role ownerRole = getRole(tx, "owner");
            Role roleplayerRole = getRole(tx, "roleplayer");
            Role relRole = getRole(tx, "rel");

            RelationType attrPropRel = tx.execute(Graql.match(Graql.var("x").sub("has-attribute-property")).get()).get(0).get("x").asRelationType();


            GraqlGet typesToConnectQuery = Graql.match(
                    Graql.var("x").sub("thing"),
                    Graql.not(Graql.var("x").sub("@has-attribute")),
                    Graql.not(Graql.var("x").sub("@key-attribute"))
            ).get();
            tx.stream(typesToConnectQuery).map(ans -> ans.get("x").asType()).forEach(type -> {
                if (type.isAttributeType()) {
                    if (!EXCLUDED_ATTRIBUTE_TYPES.contains(type.label().toString())) {
                        attrPropRel.has((AttributeType) type);
                    }
                } else if (type.isEntityType()) {
                    if (!EXCLUDED_ENTITY_TYPES.contains(type.label().toString())) {
                        type.plays(instanceRole);
                        type.plays(ownerRole);
                        type.plays(roleplayerRole);
                    }

                } else if (type.isRelationType()) {
                    if (!EXCLUDED_RELATION_TYPES.contains(type.label().toString())) {
                        type.plays(instanceRole);
                        type.plays(ownerRole);
                        type.plays(roleplayerRole);
                        type.plays(relRole);
                    }
                }
            });
            tx.commit();
        }
    }
}
