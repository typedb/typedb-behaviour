package grakn.verification.resolution.kbtest;

import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.Concept;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.query.GraqlGet;
import graql.lang.statement.Statement;
import graql.lang.statement.StatementAttribute;
import graql.lang.statement.StatementInstance;
import graql.lang.statement.Variable;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class ResolutionBuilder {

    public List<GraqlGet> build(Transaction tx, GraqlGet query) {
            List<ConceptMap> answers = tx.execute(query);

            ArrayList<GraqlGet> resolutionQueries = new ArrayList<>();
            for (ConceptMap answer : answers) {
                resolutionQueries.add(Graql.match(resolutionStatements(answer)).get());
            }
            return resolutionQueries;
    }

    private Set<Statement> resolutionStatements(ConceptMap answer) {

        Pattern qp = answer.queryPattern();

        if (qp == null) {
            throw new RuntimeException("Answer is missing a pattern. Either patterns are broken or the initial query did not require inference.");
        }

        Set<Statement> answerStatements = removeIdStatements(qp.statements());
        answerStatements.addAll(generateKeyStatements(answer.map()));

        if (answer.hasExplanation()) {
            for (ConceptMap explAns : answer.explanation().getAnswers()) {
                answerStatements.addAll(resolutionStatements(explAns));
            }
        }
        return answerStatements;
    }

    /**
     * Remove statements that stipulate ConceptIds from a given set of statements
     * @param statements set of statements to remove from
     * @return set of statements without any referring to ConceptIds
     */
    public static Set<Statement> removeIdStatements(Set<Statement> statements) {
        HashSet<Statement> withoutIds = new HashSet<>();

        for (Statement statement : statements) {
//            statement.properties().forEach(varProperty -> varProperty.uniquelyIdentifiesConcept());
            boolean containsId = statement.toString().contains(" id ");
            if (!containsId) {
                withoutIds.add(statement);
            }
        }
        return withoutIds;
    }

    /**
     * Create a set of statements that will query for the keys of the concepts given in the map. Attributes given in
     * the map are simply queried for by their own type and value.
     * @param varMap variable map of concepts
     * @return Statements that check for the keys of the given concepts
     */
    public static Set<Statement> generateKeyStatements(Map<Variable, Concept> varMap) {
        HashSet<Statement> statements = new HashSet<>();

        for (Map.Entry<Variable, Concept> entry : varMap.entrySet()) {
            Variable var = entry.getKey();
            Concept concept = entry.getValue();

            if (concept.isAttribute()) {

                Statement statement = Graql.var(var);
                StatementAttribute s = null;

                Object attrValue = concept.asAttribute().value();
                if (attrValue instanceof String) {
                    s = statement.val((String) attrValue);
                } else if (attrValue instanceof Double) {
                    s = statement.val((Double) attrValue);
                } else if (attrValue instanceof Long) {
                    s = statement.val((Long) attrValue);
                } else if (attrValue instanceof LocalDateTime) {
                    s = statement.val((LocalDateTime) attrValue);
                } else if (attrValue instanceof Boolean) {
                    s = statement.val((Boolean) attrValue);
                }
                statements.add(s);
            } else if (concept.isEntity() | concept.isRelation()){

                concept.asThing().keys().forEach(attribute -> {

                    String typeLabel = attribute.type().label().toString();
                    Statement statement = Graql.var(var);
                    Object attrValue = attribute.value();

                    StatementInstance s = null;
                    if (attrValue instanceof String) {
                        s = statement.has(typeLabel, (String) attrValue);
                    } else if (attrValue instanceof Double) {
                        s = statement.has(typeLabel, (Double) attrValue);
                    } else if (attrValue instanceof Long) {
                        s = statement.has(typeLabel, (Long) attrValue);
                    } else if (attrValue instanceof LocalDateTime) {
                        s = statement.has(typeLabel, (LocalDateTime) attrValue);
                    } else if (attrValue instanceof Boolean) {
                        s = statement.has(typeLabel, (Boolean) attrValue);
                    }
                    statements.add(s);
                });

            } else {
                throw new RuntimeException("Presently we only handle queries concerning Things, not Types");
            }
        }
        return statements;
    }

}
