package grakn.verification.resolution.complete;

import grakn.client.GraknClient;
import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.Concept;
import grakn.client.concept.ValueType;
import grakn.client.concept.type.AttributeType;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
import graql.lang.property.IsaProperty;
import graql.lang.query.GraqlGet;
import graql.lang.query.GraqlInsert;
import graql.lang.statement.Statement;
import graql.lang.statement.Variable;

import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static grakn.verification.resolution.resolve.QueryBuilder.generateKeyStatements;

public class Completer {

    private final GraknClient.Session session;
    private Set<Rule> rules;

    public Completer(GraknClient.Session session) {
        this.session = session;
    }

    public void complete() {
        boolean allRulesRerun = true;

        while (allRulesRerun) {
            allRulesRerun = false;
            try (GraknClient.Transaction tx = session.transaction().write()) {

                for (Rule rule : rules) {
                    allRulesRerun = allRulesRerun | completeRule(tx, rule);
                }
                tx.commit();
            }
        }
    }

    private static boolean completeRule(Transaction tx, Rule rule) {

        boolean foundResult = false;
//
//        Stream<ConceptMap> answerStream2 = rule.matchBodyAndHead(tx);
//        Iterator<ConceptMap> answerIt2 = answerStream2.iterator();
//
//        while (answerIt2.hasNext()) {
//            foundResult = foundResult | rule.matchBodyAndHeadAndKeysAndNotResolution_insertResolution(tx, answerIt2.next().map());
        // TODO When making match queries be careful that user-provided rules could trigger due to elements of the
        //  completion schema. These results should be filtered out.
//        }

        Stream<ConceptMap> answerStream = rule.matchBodyAndNotHead(tx);
        Iterator<ConceptMap> answerIt = answerStream.iterator();
        while (answerIt.hasNext()) {
            boolean insertedHeadAndResolution = rule.matchBodyAndKeys_insertHeadAndResolution(tx, answerIt.next().map());
            if (insertedHeadAndResolution) {
                foundResult = true;
            } else {
                throw new RuntimeException("Something has gone wrong - based on a previous query, this query should have made an insertion!");
            }
        }
        return foundResult;
    }

    public void loadRules(Transaction tx, Set<grakn.client.concept.Rule> graknRules) {
        Set<Rule> rules = new HashSet<>();
        for (grakn.client.concept.Rule graknRule : graknRules) {
            grakn.client.concept.Rule.Remote remoteRule = graknRule.asRemote(tx);
            rules.add(new Rule(Objects.requireNonNull(remoteRule.when()), Objects.requireNonNull(remoteRule.then()), graknRule.label().toString()));
        }
        this.rules = rules;
    }

    private static class Rule {
        private final Pattern body;
        private final Pattern head;
        private Set<Statement> resolution;

        Rule(Pattern when, Pattern then, String label) {
            body = QueryBuilder.makeAnonVarsExplicit(when);
            head = QueryBuilder.makeAnonVarsExplicit(then);
            QueryBuilder qb = new QueryBuilder();

            resolution = qb.inferenceStatements(this.body.statements(), this.head.statements(), label);
        }

        private Map<Variable, Concept<?>> oneAnswerFromConceptMap(List<ConceptMap> answers) {
            if (answers.size() == 1) {
                return answers.get(0).map();
            } else if (answers.size() == 0) {
                return null;
            } else {
                throw new RuntimeException("Found more than one answer in the given answers");
            }
        }

        Stream<ConceptMap> matchBodyAndNotHead(Transaction tx) {
            GraqlGet.Unfiltered query = Graql.match(body, Graql.not(head)).get();
            return tx.stream(query);
        }

        Stream<ConceptMap> matchBodyAndHead(Transaction tx) {
            GraqlGet.Unfiltered query = Graql.match(body, head).get();
            return tx.stream(query);
        }

        boolean matchBodyAndHeadAndKeysAndNotResolution_insertResolution(Transaction tx, Map<Variable, Concept<?>> matchAnswerMap) {
            Set<Statement> keyStatements = generateKeyStatements(tx, matchAnswerMap);
            GraqlInsert query = Graql.match(body, head, Graql.and(keyStatements), Graql.not(Graql.and(resolution))).insert(resolution);
            Map<Variable, Concept<?>> answerMap = oneAnswerFromConceptMap(tx.execute(query));
            return answerMap != null;
        }

        HashSet<Statement> getHeadKeyStatements(Transaction tx) {
            HashSet<Statement> keyStatements = new HashSet<>();
            head.statements().forEach(s -> {
                s.properties().forEach(p -> {
                    if (p instanceof IsaProperty) {
                        // Get the relevant type(s)
                        GraqlGet query = Graql.match(Graql.var("x").sub(((IsaProperty) p).type())).get();
                        List<ConceptMap> ans = tx.execute(query);
                        ans.forEach(a -> {
                            Set<? extends AttributeType.Remote<?>> keys = a.get("x").asType().asRemote(tx).keys().collect(Collectors.toSet());
                            keys.forEach(k -> {
                                String keyTypeLabel = k.label().toString();
                                ValueType<?> v = k.valueType();
                                String randomKeyValue = UUID.randomUUID().toString();

                                assert v != null;
                                if (v.valueClass().equals(Long.class)) {

                                    keyStatements.add(Graql.var(s.var()).has(keyTypeLabel, randomKeyValue.hashCode()));
                                } else if (v.valueClass().equals(String.class)) {

                                    keyStatements.add(Graql.var(s.var()).has(keyTypeLabel, randomKeyValue));
                                }
                            });
                        });
                    }
                });
            });
            return keyStatements;
        }

        boolean matchBodyAndKeys_insertHeadAndResolution(Transaction tx, Map<Variable, Concept<?>> matchAnswerMap) {
            Set<Statement> keyStatements = generateKeyStatements(tx, matchAnswerMap);

            HashSet<Statement> toInsert = new HashSet<>(resolution);
            HashSet<Statement> headKeyStatements = getHeadKeyStatements(tx);
            toInsert.addAll(head.statements());
            toInsert.addAll(headKeyStatements);

            GraqlInsert query = Graql.match(body, Graql.and(keyStatements)).insert(toInsert);
            System.out.print("\n----");
            System.out.print("\nmaking matchBodyAndKeys_insertHeadAndResolution query:");
            System.out.print(query);
            System.out.print("\n----");
            Map<Variable, Concept<?>> answerMap = oneAnswerFromConceptMap(tx.execute(query));

            return answerMap != null;
        }
    }
}
