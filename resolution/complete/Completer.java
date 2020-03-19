package grakn.verification.resolution.complete;

import grakn.client.GraknClient;
import grakn.client.GraknClient.Transaction;
import grakn.client.answer.ConceptMap;
import grakn.client.concept.Concept;
import grakn.verification.resolution.resolve.QueryBuilder;
import graql.lang.Graql;
import graql.lang.pattern.Pattern;
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

        Stream<ConceptMap> answerStream2 = rule.matchBodyAndHead(tx);
        Iterator<ConceptMap> answerIt2 = answerStream2.iterator();

        while (answerIt2.hasNext()) {
            foundResult = foundResult | rule.matchBodyAndHeadAndKeysAndNotResolution_insertResolution(tx, answerIt2.next().map());
        }

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

    public void loadRules(Set<grakn.client.concept.Rule> graknRules) {
        Set<Rule> rules = new HashSet<>();
        for (grakn.client.concept.Rule graknRule : graknRules) {
            rules.add(new Rule(Objects.requireNonNull(graknRule.when()), Objects.requireNonNull(graknRule.then()), graknRule.label().toString()));
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

        private Map<Variable, Concept> oneAnswerFromConceptMap(List<ConceptMap> answers) {
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

        boolean matchBodyAndHeadAndKeysAndNotResolution_insertResolution(Transaction tx, Map<Variable, Concept> matchAnswerMap) {
            Set<Statement> keyStatements = generateKeyStatements(matchAnswerMap);
            GraqlInsert query = Graql.match(body, head, Graql.and(keyStatements), Graql.not(Graql.and(resolution))).insert(resolution);
            Map<Variable, Concept> answerMap = oneAnswerFromConceptMap(tx.execute(query));
            return answerMap != null;
        }

        boolean matchBodyAndKeys_insertHeadAndResolution(Transaction tx, Map<Variable, Concept> matchAnswerMap) {
            Set<Statement> keyStatements = generateKeyStatements(matchAnswerMap);

            HashSet<Statement> toInsert = new HashSet<>(resolution);
            toInsert.addAll(head.statements());

            GraqlInsert query = Graql.match(body, Graql.and(keyStatements)).insert(toInsert);
            Map<Variable, Concept> answerMap = oneAnswerFromConceptMap(tx.execute(query));

            return answerMap != null;
        }
    }
}
