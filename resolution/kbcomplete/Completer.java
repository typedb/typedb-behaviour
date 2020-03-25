package grakn.verification.resolution.kbcomplete;

import grakn.client.GraknClient;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.AttributeType;
import grakn.client.concept.RelationType;
import grakn.client.concept.Role;
import grakn.client.concept.Type;
import graql.lang.Graql;
import graql.lang.query.GraqlDefine;
import graql.lang.query.GraqlGet;

import java.util.HashSet;
import java.util.List;

public class Completer {

    public static void addResolutionSchema(GraknClient.Transaction tx){
        GraqlDefine defineQuery = Graql.parse("define\n" +
                "rule-label sub attribute, datatype string;\n" +

                "rule-application sub entity,\n" +
                "  has rule-label,\n" +
                "  plays containing-rule;\n" +

                "clause-containment sub relation,\n" +
                "  relates containing-rule,\n" +
                "  relates clause-element;\n" +

                "then-clause-containment sub relation,\n" +
                "  relates containing-rule,\n" +
                "  relates clause-element;\n" +

                "when-clause-containment sub relation,\n" +
                "  relates containing-rule,\n" +
                "  relates clause-element;");

        tx.execute(defineQuery);
    }

    public static void defineThatAllThingsCanBePartOfAClause(GraknClient.Transaction tx){
        HashSet<String> excludedEntityTypes = new HashSet<String>() {
            {
                add("entity");
                add("rule-application");
            }
        };
        HashSet<String> excludedRelationTypes = new HashSet<String>() {
            {
                add("relation");
                add("clause-containment");
                add("then-clause-containment");
                add("when-clause-containment");
            }
        };
        HashSet<String> excludedAttributeTypes = new HashSet<String>() {
            {
                add("attribute");
                add("rule-label");
            }
        };

        GraqlGet roleQuery = Graql.match(Graql.var("x").sub("clause-element")).get();
        Role role = tx.execute(roleQuery).get(0).get("x").asRole();

        // Entities
        GraqlGet entityTypesQuery = Graql.match(Graql.var("x").sub("entity")).get();

        defineThatTypesPlayRoleFromQuery(tx, role, entityTypesQuery, excludedEntityTypes);

        // Relations
        GraqlGet relationTypesQuery = Graql.match(
                Graql.var("x").sub("relation"),
                Graql.not(Graql.var("x").sub("@has-attribute")),
                Graql.not(Graql.var("x").sub("@key-attribute"))
        ).get();

        defineThatTypesPlayRoleFromQuery(tx, role, relationTypesQuery, excludedRelationTypes);

        // Attributes
        GraqlGet attributeTypesQuery = Graql.match(Graql.var("x").sub("attribute")).get();

        defineThatAllAttributesCanBePartOfAClause(tx, attributeTypesQuery, excludedAttributeTypes);
    }

    private static void defineThatTypesPlayRoleFromQuery(GraknClient.Transaction tx, Role role, GraqlGet typesQuery, HashSet<String> excludedTypes) {
        List<ConceptMap> typeAnswers = tx.execute(typesQuery);

        for (ConceptMap typeAnswer: typeAnswers) {

            Type type = typeAnswer.get("x").asType();

            if (!excludedTypes.contains(type.label().toString())) {
                type.plays(role);
            }
        }
    }

    private static void defineThatAllAttributesCanBePartOfAClause(GraknClient.Transaction tx, GraqlGet typesQuery, HashSet<String> excludedTypes){
        List<ConceptMap> typeAnswers = tx.execute(typesQuery);

        RelationType rel = tx.execute(Graql.match(Graql.var("x").sub("clause-containment")).get()).get(0).get("x").asRelationType();

        for (ConceptMap typeAnswer: typeAnswers) {

            AttributeType type = typeAnswer.get("x").asAttributeType();

            if (!excludedTypes.contains(type.label().toString())) {
                rel.has(type);
            }
        }
    }
}
